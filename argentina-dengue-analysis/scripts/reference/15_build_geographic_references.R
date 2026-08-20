###############################################################
# Argentina Dengue Analysis
# Script: 15_build_geographic_references.R
# Purpose: Build INDEC jurisdiction and BEN region crosswalks.
###############################################################

province_columns <- c("province_reference_schema_version", "reference_province_id", "reference_province_name", "reference_system", "source_authority", "population_source_label", "population_source_label_status")
source_columns <- c("source_geography_crosswalk_schema_version", "source_schema_family", "source_province_id", "source_province_name", "reference_province_id", "reference_province_name", "mapping_status", "mapping_basis", "source_geography_semantics_status")
region_columns <- c("region_crosswalk_schema_version", "reference_province_id", "reference_province_name", "epidemiological_region", "source_authority", "source_document", "source_url", "effective_context")
validation_columns <- c("geographic_validation_schema_version", "analysis_scope_id", "source_year", "source_resource_id", "source_schema_family", "total_published_row_count", "total_published_case_count", "mapped_published_row_count", "mapped_published_case_count", "name_based_unverified_published_row_count", "name_based_unverified_published_case_count", "ambiguous_published_row_count", "ambiguous_published_case_count", "unmapped_published_row_count", "unmapped_published_case_count", "unknown_published_row_count", "unknown_published_case_count", "geographic_mapping_completeness", "source_geography_semantics_status", "rate_geography_eligibility_status", "rate_geography_reason_codes")

#' Abort C.15 with a clear contract-specific message.
abort_geographic_mapping <- function(message) stop(message, call. = FALSE)

#' Read centralized project configuration.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) abort_geographic_mapping("Configuration file not found: config/project.yml")
  yaml::read_yaml("config/project.yml")
}

#' Retrieve one safe project-relative configured artifact path.
artifact_path <- function(config, key) {
  path <- config$artifacts[[key]]
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || grepl("^(/|[[:alpha:]]:[/\\\\])", path)) abort_geographic_mapping(sprintf("Invalid artifacts.%s path.", key))
  path
}

#' Read a CSV without inference and require its ordered contract schema.
read_contract_csv <- function(path, columns, label) {
  rows <- tryCatch(readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())), error = function(error) abort_geographic_mapping(sprintf("Could not read %s: %s", label, error$message)))
  if (!identical(names(rows), columns) || nrow(readr::problems(rows))) abort_geographic_mapping(sprintf("%s has an invalid schema.", label))
  rows
}

#' Case-fold text only for controlled comparison; source values are never changed.
comparison_name <- function(value) toupper(enc2utf8(value))

#' Normalize a numeric source ID only for comparison with two-digit INDEC IDs.
comparison_id <- function(value) {
  ifelse(!is.na(value) & grepl("^[0-9]+$", value) & as.integer(value) >= 0L & as.integer(value) <= 99L, sprintf("%02d", as.integer(value)), NA_character_)
}

#' Build and validate the C.14-derived INDEC province reference.
build_province_reference <- function(population, config) {
  provinces <- dplyr::filter(population, .data$geography_level == "province")
  pairs <- dplyr::distinct(provinces, .data$projection_vintage, .data$population_year, .data$province_reference_id, .data$province_reference_name)
  population_labels <- dplyr::transmute(pairs, reference_province_id = .data$province_reference_id, population_source_label = .data$province_reference_name) |> dplyr::distinct()
  official_names <- unlist(config$geographic_mapping$indec_jurisdictions, use.names = TRUE)
  baseline <- tibble::tibble(reference_province_id = names(official_names), reference_province_name = unname(official_names))
  if (nrow(baseline) != 24L || anyDuplicated(baseline$reference_province_id) || anyDuplicated(baseline$reference_province_name) || !all(grepl("^[0-9]{2}$", baseline$reference_province_id)) || !all(c("02", "06") %in% baseline$reference_province_id) || anyDuplicated(population_labels$reference_province_id) || !setequal(population_labels$reference_province_id, baseline$reference_province_id)) abort_geographic_mapping("C.14 province IDs are not the complete official 24-jurisdiction INDEC set.")
  expected <- population_labels$reference_province_id
  observed <- dplyr::group_split(pairs, .data$projection_vintage, .data$population_year)
  if (any(vapply(observed, function(x) !setequal(x$province_reference_id, expected), logical(1)))) abort_geographic_mapping("C.14 vintages or years disagree on province IDs.")
  dplyr::left_join(baseline, population_labels, by = "reference_province_id") |>
    dplyr::transmute(province_reference_schema_version = "1.0.0", reference_province_id = .data$reference_province_id, reference_province_name = .data$reference_province_name, reference_system = "INDEC_jurisdiction", source_authority = "INDEC", population_source_label = .data$population_source_label, population_source_label_status = ifelse(comparison_name(.data$population_source_label) == comparison_name(.data$reference_province_name), "matched_official_reference", "population_source_label_mismatch")) |>
    dplyr::arrange(.data$reference_province_id) |>
    dplyr::select(dplyr::all_of(province_columns))
}

#' Classify one observed source geography category without mutating it.
classify_source_geography <- function(family, source_id, source_name, reference) {
  if (identical(family, "indec_residence_geography") && identical(source_id, "99") && identical(source_name, "desconocida")) return(list(id = NA_character_, name = NA_character_, status = "unknown_source_category", basis = "recognized_unknown_category", semantics = "unknown_not_applicable"))
  id <- comparison_id(source_id)
  id_match <- reference[reference$reference_province_id == id, , drop = FALSE]
  name_match <- reference[comparison_name(reference$reference_province_name) == comparison_name(source_name), , drop = FALSE]
  semantics <- if (identical(family, "indec_residence_geography")) "field_name_supports_residence_but_operational_semantics_undocumented" else "source_geographic_semantics_undocumented"
  if (nrow(id_match) == 1L && nrow(name_match) == 1L && identical(id_match$reference_province_id, name_match$reference_province_id)) return(list(id = id_match$reference_province_id, name = id_match$reference_province_name, status = "validated_exact", basis = "normalized_numeric_id_and_casefolded_exact_name", semantics = semantics))
  if (nrow(id_match) == 1L && nrow(name_match) == 1L && !identical(id_match$reference_province_id, name_match$reference_province_id)) return(list(id = NA_character_, name = NA_character_, status = "ambiguous", basis = "conflicting_source_id_name_mapping", semantics = semantics))
  if (nrow(id_match) == 1L && !nrow(name_match)) return(list(id = NA_character_, name = NA_character_, status = "ambiguous", basis = "conflicting_source_id_name_mapping", semantics = semantics))
  if (!nrow(id_match) && nrow(name_match) == 1L) return(list(id = name_match$reference_province_id, name = name_match$reference_province_name, status = "name_based_unverified", basis = "exact_name_only", semantics = semantics))
  list(id = NA_character_, name = NA_character_, status = "unmapped", basis = "no_reference_match", semantics = semantics)
}

#' Build one crosswalk row for each distinct source geography category.
build_source_crosswalk <- function(structural, reference) {
  pairs <- dplyr::distinct(structural, .data$source_schema_family, .data$province_id, .data$province_name) |>
    dplyr::arrange(.data$source_schema_family, .data$province_id, .data$province_name)
  mapped <- lapply(seq_len(nrow(pairs)), function(index) classify_source_geography(pairs$source_schema_family[[index]], pairs$province_id[[index]], pairs$province_name[[index]], reference))
  output <- dplyr::bind_cols(
    tibble::tibble(source_geography_crosswalk_schema_version = "1.0.0", source_schema_family = pairs$source_schema_family, source_province_id = pairs$province_id, source_province_name = pairs$province_name),
    tibble::tibble(reference_province_id = vapply(mapped, `[[`, character(1), "id"), reference_province_name = vapply(mapped, `[[`, character(1), "name"), mapping_status = vapply(mapped, `[[`, character(1), "status"), mapping_basis = vapply(mapped, `[[`, character(1), "basis"), source_geography_semantics_status = vapply(mapped, `[[`, character(1), "semantics"))
  )
  output[, source_columns]
}

#' Build the configured BEN region mapping through the C.14 reference.
build_region_crosswalk <- function(config, reference) {
  regions <- config$geographic_mapping$ben_regions
  if (!is.list(regions) || !length(regions)) abort_geographic_mapping("BEN regionalization configuration is missing.")
  pairs <- dplyr::bind_rows(lapply(names(regions), function(region) tibble::tibble(reference_province_id = unlist(regions[[region]], use.names = FALSE), epidemiological_region = region)))
  if (nrow(pairs) != 24L || anyDuplicated(pairs$reference_province_id) || !setequal(pairs$reference_province_id, reference$reference_province_id)) abort_geographic_mapping("Configured BEN regions do not cover the INDEC reference exactly once.")
  dplyr::left_join(pairs, reference[c("reference_province_id", "reference_province_name")], by = "reference_province_id") |>
    dplyr::mutate(region_crosswalk_schema_version = "1.0.0", source_authority = "Ministerio de Salud de la Nación", source_document = config$geographic_mapping$ben_region_source_document, source_url = config$geographic_mapping$ben_region_source_url, effective_context = config$geographic_mapping$ben_region_effective_context) |>
    dplyr::arrange(.data$reference_province_id) |>
    dplyr::select(dplyr::all_of(region_columns))
}

#' Create stable pipe-delimited reason codes.
reason_codes <- function(values) paste(sort(unique(values[nzchar(values)])), collapse = "|")

#' Build one scope-level mapping-completeness record.
assess_scope_mapping <- function(scope, crosswalk) {
  joined <- dplyr::left_join(scope, crosswalk[c("source_schema_family", "source_province_id", "source_province_name", "mapping_status", "source_geography_semantics_status")], by = c("source_schema_family", "province_id" = "source_province_id", "province_name" = "source_province_name"))
  if (any(is.na(joined$mapping_status))) abort_geographic_mapping("A scope source geography category is absent from the crosswalk.")
  count_status <- function(status, field) if (identical(field, "rows")) sum(joined$mapping_status == status) else sum(joined$source_case_count[joined$mapping_status == status])
  mapped <- joined$mapping_status %in% c("documented_exact", "validated_exact")
  family <- unique(joined$source_schema_family)
  semantics <- unique(joined$source_geography_semantics_status[joined$mapping_status != "unknown_source_category"])
  if (length(family) != 1L || length(semantics) != 1L) abort_geographic_mapping("Scope has inconsistent geographic family semantics.")
  known_complete <- all(joined$mapping_status[ joined$mapping_status != "unknown_source_category"] %in% c("documented_exact", "validated_exact") )
  issues <- c(if (semantics == "source_geographic_semantics_undocumented") semantics else "field_name_supports_residence_but_operational_semantics_undocumented", if (any(joined$mapping_status == "unknown_source_category")) "unknown_geography_present", if (any(joined$mapping_status == "name_based_unverified")) "name_based_mapping_present", if (any(joined$mapping_status == "ambiguous")) "ambiguous_mapping_present", if (any(joined$mapping_status == "unmapped")) "unmapped_geography_present", if (known_complete) "complete_known_geography_mapping")
  eligibility <- if (identical(family, "indec_residence_geography") && known_complete) "supported_with_caveats" else "unsupported"
  tibble::tibble(geographic_validation_schema_version = "1.0.0", analysis_scope_id = unique(joined$analysis_scope_id), source_year = as.integer(unique(joined$source_year)), source_resource_id = unique(joined$source_resource_id), source_schema_family = family, total_published_row_count = nrow(joined), total_published_case_count = sum(joined$source_case_count), mapped_published_row_count = sum(mapped), mapped_published_case_count = sum(joined$source_case_count[mapped]), name_based_unverified_published_row_count = count_status("name_based_unverified", "rows"), name_based_unverified_published_case_count = count_status("name_based_unverified", "cases"), ambiguous_published_row_count = count_status("ambiguous", "rows"), ambiguous_published_case_count = count_status("ambiguous", "cases"), unmapped_published_row_count = count_status("unmapped", "rows"), unmapped_published_case_count = count_status("unmapped", "cases"), unknown_published_row_count = count_status("unknown_source_category", "rows"), unknown_published_case_count = count_status("unknown_source_category", "cases"), geographic_mapping_completeness = sum(joined$source_case_count[mapped]) / sum(joined$source_case_count), source_geography_semantics_status = semantics, rate_geography_eligibility_status = eligibility, rate_geography_reason_codes = reason_codes(issues))
}

#' Atomically publish one versioned mapping artifact.
publish_csv <- function(rows, path, label) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(paste0(".", label, "_"), tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(rows, temporary, na = "")
  if (!file.rename(temporary, path)) abort_geographic_mapping(sprintf("Could not publish %s.", label))
}

#' Build all C.15 references and mapping assessment artifacts.
main <- function() {
  config <- read_project_config()
  population_columns <- c("population_schema_version", "source_resource_identifier", "geography_level", "population_year", "province_reference_id", "province_reference_name", "population", "population_scope", "projection_vintage", "census_basis", "reference_date")
  structural_columns <- c("source_resource_id", "source_local_filename", "source_row_number", "source_schema_family", "province_id", "province_name", "department_id", "department_name", "source_year", "source_week", "event", "source_age_group_id", "source_age_group_label", "source_case_count")
  scope_columns <- c("multiyear_scope_schema_version", "analysis_scope_id", structural_columns)
  population <- read_contract_csv(artifact_path(config, "population_denominators"), population_columns, "population denominators")
  structural <- read_contract_csv(artifact_path(config, "canonical_resources_structural"), structural_columns, "structural harmonization")
  scopes <- read_contract_csv(artifact_path(config, "multiyear_dengue_scopes"), scope_columns, "multiyear Dengue scopes")
  population$population_year <- as.integer(population$population_year); scopes$source_year <- as.integer(scopes$source_year); scopes$source_case_count <- as.numeric(scopes$source_case_count)
  reference <- build_province_reference(population, config)
  crosswalk <- build_source_crosswalk(structural, reference)
  regions <- build_region_crosswalk(config, reference)
  snapshot <- dplyr::group_split(scopes, .data$analysis_scope_id, .data$source_year, .data$source_resource_id) |> lapply(assess_scope_mapping, crosswalk = crosswalk) |> dplyr::bind_rows() |> dplyr::arrange(.data$source_year) |> dplyr::select(dplyr::all_of(validation_columns))
  if (nrow(snapshot) != 4L || anyDuplicated(snapshot[c("analysis_scope_id", "source_year")])) abort_geographic_mapping("C.15 scope snapshot cardinality failed.")
  publish_csv(reference, artifact_path(config, "province_reference"), "province_reference")
  publish_csv(crosswalk, artifact_path(config, "source_geography_crosswalk"), "source_geography_crosswalk")
  publish_csv(regions, artifact_path(config, "province_region_crosswalk"), "province_region_crosswalk")
  publish_csv(snapshot, artifact_path(config, "geographic_mapping_validation_snapshot"), "geographic_mapping_validation_snapshot")
  invisible(snapshot)
}

if (sys.nframe() == 0L) main()
