###############################################################
# Argentina Dengue Analysis
# Script: 13_assess_multiyear_comparability.R
# Purpose: Publish descriptive comparability metadata by canonical year.
###############################################################

quality_types <- c("exact_content_duplicate", "same_candidate_dimensions_same_count", "same_candidate_dimensions_count_conflict", "province_id_name_conflict", "department_id_name_conflict", "age_group_id_label_conflict", "text_source_anomaly", "event_dimension_overlap")

#' Abort comparability assessment with a contract-specific error.
abort_comparability <- function(message) stop(message, call. = FALSE)

#' Read central project configuration.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) abort_comparability("Configuration file not found: config/project.yml")
  yaml::read_yaml("config/project.yml")
}

#' Retrieve one required project-relative artifact path.
artifact_path <- function(config, key) {
  path <- config$artifacts[[key]]
  if (is.null(path) || length(path) != 1L || !is.character(path) || !nzchar(path) || grepl("^(/|[[:alpha:]]:[/\\\\])", path)) abort_comparability(sprintf("Invalid artifacts.%s path.", key))
  path
}

#' Read a CSV as character data and require its expected columns.
read_contract_csv <- function(path, columns, label) {
  rows <- tryCatch(readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())), error = function(error) abort_comparability(sprintf("Could not read %s: %s", label, error$message)))
  if (!all(columns %in% names(rows)) || nrow(readr::problems(rows))) abort_comparability(sprintf("%s is malformed or contract-incompatible.", label))
  rows
}

#' Serialize a sorted integer set as a deterministic pipe-delimited string.
week_set <- function(values) paste(sprintf("%02d", sort(unique(as.integer(values)))), collapse = "|")

#' Serialize zero or more controlled reason codes deterministically.
reason_codes <- function(values) if (!length(values)) "" else paste(sort(unique(values)), collapse = "|")

#' Count scope-attributable C.7 diagnostic groups for one resource and type.
scope_quality_count <- function(quality, scope_keys, resource_id, type) {
  rows <- dplyr::filter(quality, .data$diagnostic_type == type, .data$source_resource_id == resource_id, !is.na(.data$source_row_number))
  if (!nrow(rows)) return(0L)
  keys <- paste(scope_keys$source_resource_id, scope_keys$source_row_number, sep = "|")
  rows <- dplyr::filter(rows, paste(.data$source_resource_id, .data$source_row_number, sep = "|") %in% keys)
  dplyr::n_distinct(rows$diagnostic_group_id)
}

#' Publish a complete snapshot atomically.
publish_snapshot <- function(rows, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(".multiyear_comparability_", tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(rows, temporary, na = "")
  if (!file.rename(temporary, path)) abort_comparability(sprintf("Could not publish comparability snapshot: %s", path))
}

#' Assess one canonical Dengue scope without changing its observations.
assess_scope <- function(scope, structural, quality) {
  resource_id <- unique(scope$source_resource_id)
  resource <- dplyr::filter(structural, .data$source_resource_id == resource_id)
  family <- unique(scope$source_schema_family)
  recognized_unknown <- identical(family, "indec_residence_geography")
  unknown <- scope$province_id == "99" & scope$province_name == "desconocida"
  unknown[is.na(unknown)] <- FALSE
  known_rows <- sum(!unknown); unknown_rows <- sum(unknown)
  known_cases <- sum(scope$source_case_count[!unknown]); unknown_cases <- sum(scope$source_case_count[unknown]); total_cases <- sum(scope$source_case_count)
  age_map <- dplyr::summarise(dplyr::group_by(scope, .data$source_age_group_id), labels = dplyr::n_distinct(.data$source_age_group_label), .groups = "drop")
  age_conflicts <- sum(age_map$labels > 1L)
  observed_weeks <- week_set(scope$source_week)
  quality_count <- function(type) scope_quality_count(quality, scope[c("source_resource_id", "source_row_number")], resource_id, type)
  temporal_reasons <- c("expected_epidemiological_calendar_not_defined", if (length(unique(scope$source_week)) != (max(scope$source_week) - min(scope$source_week) + 1L)) "observed_week_set_noncontiguous")
  geography_reasons <- c(if (recognized_unknown && unknown_cases > 0L) "unknown_geography_present", if (quality_count("province_id_name_conflict") > 0L) "province_id_name_conflict", if (quality_count("department_id_name_conflict") > 0L) "department_id_name_conflict", if (!recognized_unknown) "source_geographic_semantics_undocumented")
  age_reasons <- c(if (age_conflicts > 0L) "inconsistent_source_vocabulary", if (quality_count("text_source_anomaly") > 0L) "text_source_anomaly_preserved")
  comparison_reasons <- c("cross_year_geography_crosswalk_not_established", "cross_year_numerator_comparability_not_established", "cross_year_observed_week_coverage_differs", "expected_epidemiological_calendar_not_defined")
  tibble::tibble(
    comparability_schema_version = "1.0.0", source_year = unique(scope$source_year), source_resource_id = resource_id, source_local_filename = unique(scope$source_local_filename), source_schema_family = family,
    resource_observed_event_set = paste(sort(unique(resource$event)), collapse = "|"), dengue_scope_exists = TRUE,
    dengue_published_row_count = nrow(scope), dengue_published_case_count = total_cases, dengue_observed_week_count = dplyr::n_distinct(scope$source_week), dengue_observed_week_set = observed_weeks, dengue_coverage_start_week = min(scope$source_week), dengue_coverage_end_week = max(scope$source_week), expected_calendar_status = "not_defined", expected_week_count = NA_integer_, expected_week_set = NA_character_,
    observed_province_id_count = dplyr::n_distinct(scope$province_id), observed_province_category_count = dplyr::n_distinct(paste(scope$province_id, scope$province_name, sep = "|")),
    known_geography_published_row_count = if (recognized_unknown) known_rows else NA_integer_, unknown_geography_published_row_count = if (recognized_unknown) unknown_rows else NA_integer_, known_geography_published_case_count = if (recognized_unknown) known_cases else NA_integer_, unknown_geography_published_case_count = if (recognized_unknown) unknown_cases else NA_integer_, unknown_geography_published_case_share = if (recognized_unknown && total_cases > 0L) unknown_cases / total_cases else NA_real_, geographic_assignment_completeness = if (recognized_unknown && total_cases > 0L) known_cases / total_cases else NA_real_, unknown_geography_recognition_status = if (recognized_unknown) "recognized_99_desconocida" else "not_recognized_no_assumption", geographic_semantics_status = "source_semantics_undocumented",
    dengue_age_group_id_count = dplyr::n_distinct(scope$source_age_group_id), dengue_age_group_label_count = dplyr::n_distinct(scope$source_age_group_label), dengue_age_group_id_label_pair_count = dplyr::n_distinct(paste(scope$source_age_group_id, scope$source_age_group_label, sep = "|")), dengue_age_group_id_label_conflict_group_count = quality_count("age_group_id_label_conflict"), dengue_age_semantics_status = if (age_conflicts > 0L) "inconsistent_source_vocabulary" else "consistent_within_resource_source_vocabulary",
    dengue_exact_duplicate_group_count = quality_count("exact_content_duplicate"), dengue_same_candidate_dimensions_same_count_group_count = quality_count("same_candidate_dimensions_same_count"), dengue_same_candidate_dimensions_count_conflict_group_count = quality_count("same_candidate_dimensions_count_conflict"), dengue_province_id_name_conflict_group_count = quality_count("province_id_name_conflict"), dengue_department_id_name_conflict_group_count = quality_count("department_id_name_conflict"), dengue_text_source_anomaly_group_count = quality_count("text_source_anomaly"), dengue_event_dimension_overlap_group_count = quality_count("event_dimension_overlap"), quality_evidence_attribution_status = "row_attributable",
    weekly_national_status = "supported_with_caveats", weekly_national_reason_codes = reason_codes(c(temporal_reasons, if (quality_count("same_candidate_dimensions_count_conflict") > 0L) "candidate_dimension_count_conflicts_preserved", if (quality_count("exact_content_duplicate") > 0L) "exact_duplicates_preserved")),
    province_descriptive_status = "supported_with_caveats", province_descriptive_reason_codes = reason_codes(geography_reasons), weekly_province_status = "supported_with_caveats", weekly_province_reason_codes = reason_codes(geography_reasons), age_descriptive_status = "supported_with_caveats", age_descriptive_reason_codes = reason_codes(age_reasons), annual_comparison_status = "unsupported", annual_comparison_reason_codes = reason_codes(comparison_reasons), interannual_province_comparison_status = "unsupported", interannual_province_comparison_reason_codes = reason_codes(comparison_reasons), rate_analysis_status = "pending_reference_data", rate_analysis_reason_codes = "cross_year_geography_crosswalk_not_established|population_denominators_not_available", season_analysis_status = if (unique(scope$source_year) %in% c(2024L, 2025L)) "pending_reference_data" else "unsupported", season_analysis_reason_codes = if (unique(scope$source_year) %in% c(2024L, 2025L)) "season_reference_policy_not_defined" else ""
  )
}

#' Build and publish the deterministic multiyear comparability snapshot.
main <- function() {
  config <- read_project_config()
  scope <- read_contract_csv(artifact_path(config, "multiyear_dengue_scopes"), c("multiyear_scope_schema_version", "analysis_scope_id", "source_resource_id", "source_local_filename", "source_row_number", "source_schema_family", "source_year", "source_week", "event", "source_case_count"), "multiyear scope")
  structural <- read_contract_csv(artifact_path(config, "canonical_resources_structural"), c("source_resource_id", "source_row_number", "event"), "structural artifact")
  quality <- read_contract_csv(artifact_path(config, "harmonized_quality_snapshot"), c("diagnostic_group_id", "diagnostic_type", "source_resource_id", "source_row_number"), "quality snapshot")
  for (field in c("source_row_number", "source_year", "source_week", "source_case_count")) scope[[field]] <- as.integer(scope[[field]])
  snapshots <- dplyr::group_split(scope, .data$source_year, .data$source_resource_id) |> lapply(assess_scope, structural = structural, quality = quality) |> dplyr::bind_rows() |> dplyr::arrange(.data$source_year, .data$source_resource_id)
  if (nrow(snapshots) != dplyr::n_distinct(scope[c("source_year", "source_resource_id")])) abort_comparability("Snapshot cardinality invariant failed.")
  publish_snapshot(snapshots, artifact_path(config, "multiyear_comparability_snapshot"))
  invisible(snapshots)
}

if (sys.nframe() == 0L) main()
