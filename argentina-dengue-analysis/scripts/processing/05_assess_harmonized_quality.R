###############################################################
# Argentina Dengue Analysis
# Script: 05_assess_harmonized_quality.R
# Purpose: Publish reproducible quality findings for structural records.
# Inputs: project configuration and structural harmonization artifact.
# Output: deterministic harmonized-quality snapshot in metadata.
###############################################################

quality_snapshot_columns <- c(
  "quality_schema_version", "diagnostic_group_id", "diagnostic_type",
  "diagnostic_domain", "severity", "source_resource_id",
  "source_row_number", "source_schema_family", "source_year", "source_week",
  "field_name", "group_size", "context_resource_id"
)

structural_columns <- c(
  "source_resource_id", "source_local_filename", "source_row_number",
  "source_schema_family", "province_id", "province_name", "department_id",
  "department_name", "source_year", "source_week", "event",
  "source_age_group_id", "source_age_group_label", "source_case_count"
)

diagnostic_policy <- tibble::tribble(
  ~diagnostic_type, ~diagnostic_domain, ~severity,
  "exact_content_duplicate", "row_identity", "blocking",
  "same_candidate_dimensions_same_count", "row_identity", "blocking",
  "same_candidate_dimensions_count_conflict", "row_identity", "blocking",
  "province_id_name_conflict", "geography", "blocking",
  "department_id_name_conflict", "geography", "blocking",
  "unknown_geography", "geography", "warning",
  "age_group_id_label_conflict", "age_group", "blocking",
  "unspecified_age_group", "age_group", "warning",
  "text_source_anomaly", "text", "warning",
  "no_published_rows_for_week", "temporal_coverage", "info",
  "event_dimension_overlap", "event_semantics", "blocking"
)

#' Stop quality assessment with a contract-specific execution error.
#'
#' @param message Error message.
#' @return This function does not return.
abort_quality_assessment <- function(message) {
  stop(message, call. = FALSE)
}

#' Read project configuration from its fixed bootstrap path.
#'
#' @return Parsed YAML configuration.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) {
    abort_quality_assessment("Configuration file not found: config/project.yml")
  }
  tryCatch(
    yaml::read_yaml("config/project.yml"),
    error = function(error) abort_quality_assessment(sprintf("Could not read configuration: %s", error$message))
  )
}

#' Retrieve one required scalar configuration string.
#'
#' @param config Parsed YAML configuration.
#' @param section First-level configuration section.
#' @param key Required key within the section.
#' @return Trimmed configuration string.
required_string <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (is.null(value) || length(value) != 1L || !is.character(value) || is.na(value) || !nzchar(trimws(value))) {
    abort_quality_assessment(sprintf("Missing or invalid configuration value: %s.%s", section, key))
  }
  trimws(value)
}

#' Require a configuration path to be project-relative.
#'
#' @param path Configured path.
#' @param label Configuration label.
#' @return Invisibly returns the path.
require_relative_path <- function(path, label) {
  if (grepl("^(/|[[:alpha:]]:[/\\\\])", path)) {
    abort_quality_assessment(sprintf("%s must be relative to the project root: %s", label, path))
  }
  invisible(path)
}

#' Determine whether a path is contained by a configured project directory.
#'
#' @param path Candidate project-relative path.
#' @param directory Project-relative parent directory.
#' @return Logical scalar.
inside_directory <- function(path, directory) {
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidate <- normalizePath(file.path(root, path), winslash = "/", mustWork = FALSE)
  parent <- normalizePath(file.path(root, directory), winslash = "/", mustWork = FALSE)
  startsWith(candidate, paste0(parent, "/"))
}

#' Validate configuration used by quality assessment.
#'
#' @param config Parsed YAML configuration.
#' @return Named list of validated paths.
quality_assessment_config <- function(config) {
  paths <- list(
    processed_directory = required_string(config, "directories", "processed_data"),
    metadata_directory = required_string(config, "directories", "metadata"),
    input_path = required_string(config, "artifacts", "canonical_resources_structural"),
    output_path = required_string(config, "artifacts", "harmonized_quality_snapshot")
  )
  purrr::iwalk(paths, require_relative_path)
  if (!inside_directory(paths$input_path, paths$processed_directory)) {
    abort_quality_assessment("Structural input must belong to the processed-data directory.")
  }
  if (!inside_directory(paths$output_path, paths$metadata_directory)) {
    abort_quality_assessment("Quality snapshot must belong to the metadata directory.")
  }
  paths
}

#' Parse strict decimal integer strings within a contractual range.
#'
#' @param values Character values to parse.
#' @param field Field name for diagnostics.
#' @param minimum Minimum accepted value.
#' @param maximum Maximum accepted value.
#' @return Integer vector.
parse_contract_integer <- function(values, field, minimum, maximum = .Machine$integer.max) {
  if (any(is.na(values)) || any(!grepl("^[0-9]+$", values))) {
    abort_quality_assessment(sprintf("Structural field %s is missing or not a decimal integer.", field))
  }
  parsed <- suppressWarnings(as.integer(values))
  if (any(is.na(parsed)) || any(parsed < minimum | parsed > maximum)) {
    abort_quality_assessment(sprintf("Structural field %s is outside its contractual range.", field))
  }
  parsed
}

#' Read and validate the structural-harmonization artifact.
#'
#' @param path Configured input path.
#' @return Typed structural rows.
read_structural_artifact <- function(path) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) {
    abort_quality_assessment(sprintf("Structural harmonization artifact is missing or not a regular file: %s", path))
  }
  rows <- tryCatch(
    readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())),
    error = function(error) abort_quality_assessment(sprintf("Could not read structural harmonization artifact: %s", error$message))
  )
  if (!identical(names(rows), structural_columns) || nrow(readr::problems(rows))) {
    abort_quality_assessment("Structural artifact does not satisfy structural_harmonization schema 1.0.0.")
  }
  required_text <- c("source_resource_id", "source_local_filename", "source_schema_family")
  if (!nrow(rows) || any(vapply(required_text, function(column) any(is.na(rows[[column]]) | !nzchar(rows[[column]])), logical(1)))) {
    abort_quality_assessment("Structural artifact has missing required provenance or schema-family values.")
  }
  rows$source_row_number <- parse_contract_integer(rows$source_row_number, "source_row_number", 1L)
  rows$source_year <- parse_contract_integer(rows$source_year, "source_year", 1000L, 9999L)
  rows$source_week <- parse_contract_integer(rows$source_week, "source_week", 1L, 53L)
  rows$source_case_count <- parse_contract_integer(rows$source_case_count, "source_case_count", 0L)
  if (any(!rows$source_schema_family %in% c("generic_geography", "indec_residence_geography")) || anyDuplicated(rows[c("source_resource_id", "source_row_number")])) {
    abort_quality_assessment("Structural artifact has an invalid schema family or non-unique source provenance.")
  }
  resource_shape <- dplyr::summarise(
    dplyr::group_by(rows, .data$source_resource_id),
    filenames = dplyr::n_distinct(.data$source_local_filename),
    families = dplyr::n_distinct(.data$source_schema_family),
    sequential_rows = identical(sort(.data$source_row_number), seq_len(dplyr::n())),
    .groups = "drop"
  )
  if (any(resource_shape$filenames != 1L | resource_shape$families != 1L | !resource_shape$sequential_rows)) {
    abort_quality_assessment("Structural artifact violates per-resource filename, family, or row-number invariants.")
  }
  rows
}

#' Encode one scalar deterministically for a canonical finding key.
#'
#' @param value Scalar value, potentially missing.
#' @return Length-prefixed UTF-8 representation.
canonical_scalar <- function(value) {
  if (is.na(value)) return("NA")
  text <- enc2utf8(as.character(value))
  paste0(nchar(text, type = "bytes"), ":", text)
}

#' Encode a vector deterministically for canonical finding keys.
#'
#' @param values Vector whose elements may be missing.
#' @return Length-prefixed UTF-8 representations.
canonical_values <- function(values) {
  missing <- is.na(values)
  text <- enc2utf8(as.character(values))
  encoded <- paste0(nchar(text, type = "bytes"), ":", text)
  encoded[missing] <- "NA"
  encoded
}

#' Build deterministic grouping keys for all rows without order dependence.
#'
#' @param rows Data frame.
#' @param columns Fields in contractual key order.
#' @return Character grouping-key vector.
canonical_keys <- function(rows, columns) {
  parts <- lapply(columns, function(column) paste0(column, ":", canonical_values(rows[[column]])))
  do.call(paste, c(parts, sep = "|"))
}

#' Create a deterministic identifier for one diagnostic group.
#'
#' @param diagnostic_type Controlled diagnostic type.
#' @param finding_key Canonical finding key.
#' @return Lowercase SHA-256 hexadecimal identifier.
diagnostic_group_id <- function(diagnostic_type, finding_key) {
  payload <- enc2utf8(paste0("diagnostic_type:", canonical_scalar(diagnostic_type), "|", finding_key))
  paste(sprintf("%02x", as.integer(openssl::sha256(charToRaw(payload)))), collapse = "")
}

#' Build snapshot rows for observation-backed diagnostic groups.
#'
#' @param rows Structural rows.
#' @param groups Named list of source-row indices by canonical finding key.
#' @param diagnostic_type Controlled diagnostic type.
#' @param field_name Assessed field or field set.
#' @return Snapshot tibble.
observation_findings <- function(rows, groups, diagnostic_type, field_name) {
  requested_type <- diagnostic_type
  policy <- dplyr::filter(diagnostic_policy, .data$diagnostic_type == requested_type)
  purrr::imap_dfr(groups, function(indices, finding_key) {
    tibble::tibble(
      quality_schema_version = "1.0.0",
      diagnostic_group_id = diagnostic_group_id(requested_type, finding_key),
      diagnostic_type = requested_type,
      diagnostic_domain = policy$diagnostic_domain,
      severity = policy$severity,
      source_resource_id = rows$source_resource_id[indices],
      source_row_number = rows$source_row_number[indices],
      source_schema_family = rows$source_schema_family[indices],
      source_year = rows$source_year[indices],
      source_week = rows$source_week[indices],
      field_name = field_name,
      group_size = as.integer(length(indices)),
      context_resource_id = NA_character_
    )
  })
}

#' Select repeated groups using a complete canonical key.
#'
#' @param rows Structural rows.
#' @param columns Fields defining one grouping.
#' @return Named list of repeated row-index groups.
repeated_groups <- function(rows, columns) {
  groups <- split(seq_len(nrow(rows)), canonical_keys(rows, columns))
  groups[lengths(groups) > 1L]
}

#' Select groups with more than one distinct value in a target field.
#'
#' @param rows Structural rows.
#' @param grouping_columns Fields defining one group.
#' @param value_column Field expected to have a consistent value.
#' @return Named list of conflicting row-index groups.
value_conflict_groups <- function(rows, grouping_columns, value_column) {
  groups <- split(seq_len(nrow(rows)), canonical_keys(rows, grouping_columns))
  groups[vapply(groups, function(indices) length(unique(canonical_values(rows[[value_column]][indices]))) > 1L, logical(1))]
}

#' Identify unknown source geography under the exact approved text vocabulary.
#'
#' @param rows Structural rows.
#' @return Named list of affected row-index groups.
unknown_geography_groups <- function(rows) {
  unknown_values <- c("desconocida", "desconocido")
  affected <- which(tolower(rows$province_name) %in% unknown_values | tolower(rows$department_name) %in% unknown_values)
  if (!length(affected)) return(list())
  fields <- c("source_schema_family", "province_id", "province_name", "department_id", "department_name")
  split(affected, canonical_keys(rows[affected, , drop = FALSE], fields))
}

#' Identify explicit age-group labels that mean unspecified in the source.
#'
#' @param rows Structural rows.
#' @return Named list of affected row-index groups.
unspecified_age_groups <- function(rows) {
  affected <- which(tolower(rows$source_age_group_label) == "sin especificar")
  if (!length(affected)) return(list())
  fields <- c("source_resource_id", "source_schema_family", "source_age_group_id", "source_age_group_label")
  split(affected, canonical_keys(rows[affected, , drop = FALSE], fields))
}

#' Identify the contractually defined preserved text anomaly.
#'
#' @param rows Structural rows.
#' @return Named list of affected row-index groups.
text_anomaly_groups <- function(rows) {
  affected <- which(!is.na(rows$source_age_group_label) & grepl("dÍas", rows$source_age_group_label, fixed = TRUE))
  if (!length(affected)) return(list())
  fields <- c("source_resource_id", "source_schema_family", "source_age_group_label")
  split(affected, canonical_keys(rows[affected, , drop = FALSE], fields))
}

#' Identify observation groups where both approved dengue event labels overlap.
#'
#' @param rows Structural rows.
#' @return Named list of affected row-index groups.
event_overlap_groups <- function(rows) {
  event_labels <- c("Dengue", "Dengue durante la gestación")
  candidates <- which(rows$event %in% event_labels)
  if (!length(candidates)) return(list())
  fields <- c("source_schema_family", "province_id", "province_name", "department_id", "department_name", "source_year", "source_week", "source_age_group_id", "source_age_group_label")
  groups <- split(candidates, canonical_keys(rows[candidates, , drop = FALSE], fields))
  groups[vapply(groups, function(indices) all(event_labels %in% unique(rows$event[indices])), logical(1))]
}

#' Build absence findings for weeks with no published records.
#'
#' @param rows Structural rows.
#' @return Snapshot tibble.
no_published_week_findings <- function(rows) {
  resources <- dplyr::distinct(rows, .data$source_resource_id, .data$source_schema_family, .data$source_year)
  policy <- dplyr::filter(diagnostic_policy, .data$diagnostic_type == "no_published_rows_for_week")
  purrr::pmap_dfr(resources, function(source_resource_id, source_schema_family, source_year) {
    context_id <- source_resource_id
    context_family <- source_schema_family
    context_year <- source_year
    observed <- rows$source_week[rows$source_resource_id == context_id & rows$source_year == context_year]
    missing_weeks <- setdiff(seq_len(53L), unique(observed))
    if (!length(missing_weeks)) return(tibble::tibble())
    purrr::map_dfr(missing_weeks, function(source_week) {
      finding_key <- paste(
        paste0("context_resource_id:", canonical_scalar(context_id)),
        paste0("source_schema_family:", canonical_scalar(context_family)),
        paste0("source_year:", canonical_scalar(context_year)),
        paste0("source_week:", canonical_scalar(source_week)),
        sep = "|"
      )
      tibble::tibble(
        quality_schema_version = "1.0.0",
        diagnostic_group_id = diagnostic_group_id("no_published_rows_for_week", finding_key),
        diagnostic_type = "no_published_rows_for_week",
        diagnostic_domain = policy$diagnostic_domain,
        severity = policy$severity,
        source_resource_id = NA_character_,
        source_row_number = NA_integer_,
        source_schema_family = context_family,
        source_year = as.integer(context_year),
        source_week = as.integer(source_week),
        field_name = "source_week",
        group_size = 0L,
        context_resource_id = context_id
      )
    })
  })
}

#' Construct every contractual quality finding without changing structural rows.
#'
#' @param rows Validated structural rows.
#' @return Completed snapshot tibble.
build_quality_snapshot <- function(rows) {
  exact_columns <- setdiff(structural_columns, c("source_resource_id", "source_local_filename", "source_row_number"))
  candidate_columns <- c("source_schema_family", "province_id", "department_id", "source_year", "source_week", "event", "source_age_group_id")
  findings <- list(
    observation_findings(rows, repeated_groups(rows, exact_columns), "exact_content_duplicate", "all_structural_fields_except_provenance"),
    observation_findings(rows, repeated_groups(rows, c(candidate_columns, "source_case_count")), "same_candidate_dimensions_same_count", "candidate_dimensions_and_source_case_count"),
    observation_findings(rows, value_conflict_groups(rows, candidate_columns, "source_case_count"), "same_candidate_dimensions_count_conflict", "candidate_dimensions"),
    observation_findings(rows, value_conflict_groups(rows, c("source_schema_family", "province_id"), "province_name"), "province_id_name_conflict", "province_name"),
    observation_findings(rows, value_conflict_groups(rows, c("source_schema_family", "province_id", "department_id"), "department_name"), "department_id_name_conflict", "department_name"),
    observation_findings(rows, unknown_geography_groups(rows), "unknown_geography", "province_name_or_department_name"),
    observation_findings(rows, value_conflict_groups(rows, c("source_resource_id", "source_schema_family", "source_age_group_id"), "source_age_group_label"), "age_group_id_label_conflict", "source_age_group_label"),
    observation_findings(rows, unspecified_age_groups(rows), "unspecified_age_group", "source_age_group_label"),
    observation_findings(rows, text_anomaly_groups(rows), "text_source_anomaly", "source_age_group_label"),
    no_published_week_findings(rows),
    observation_findings(rows, event_overlap_groups(rows), "event_dimension_overlap", "event")
  )
  snapshot <- dplyr::bind_rows(findings)
  if (!nrow(snapshot)) {
    snapshot <- tibble::as_tibble(stats::setNames(replicate(length(quality_snapshot_columns), logical(), simplify = FALSE), quality_snapshot_columns))
  }
  snapshot <- snapshot[, quality_snapshot_columns]
  dplyr::arrange(
    snapshot,
    .data$diagnostic_type,
    .data$diagnostic_group_id,
    dplyr::desc(is.na(.data$source_resource_id)), .data$source_resource_id,
    dplyr::desc(is.na(.data$source_row_number)), .data$source_row_number
  )
}

#' Validate snapshot schema, vocabularies, and provenance before publication.
#'
#' @param snapshot Completed candidate snapshot.
#' @param structural_rows Validated structural input.
#' @return Invisibly TRUE when valid.
validate_quality_snapshot <- function(snapshot, structural_rows) {
  if (!identical(names(snapshot), quality_snapshot_columns) || any(snapshot$quality_schema_version != "1.0.0") || any(!grepl("^[0-9a-f]{64}$", snapshot$diagnostic_group_id))) {
    abort_quality_assessment("Quality snapshot schema version or diagnostic identifiers are invalid.")
  }
  policy_match <- dplyr::inner_join(snapshot, diagnostic_policy, by = "diagnostic_type", suffix = c("", "_expected"))
  if (nrow(policy_match) != nrow(snapshot) || any(policy_match$diagnostic_domain != policy_match$diagnostic_domain_expected) || any(policy_match$severity != policy_match$severity_expected) || any(snapshot$group_size < 0L)) {
    abort_quality_assessment("Quality snapshot controlled vocabularies or severities are invalid.")
  }
  source_backed <- !is.na(snapshot$source_resource_id) | !is.na(snapshot$source_row_number)
  if (any(xor(is.na(snapshot$source_resource_id), is.na(snapshot$source_row_number))) || any(!is.na(snapshot$context_resource_id[source_backed]))) {
    abort_quality_assessment("Quality snapshot source provenance is structurally invalid.")
  }
  source_keys <- paste(structural_rows$source_resource_id, structural_rows$source_row_number, sep = "\r")
  snapshot_keys <- paste(snapshot$source_resource_id[source_backed], snapshot$source_row_number[source_backed], sep = "\r")
  if (any(!snapshot_keys %in% source_keys) || any(snapshot$diagnostic_type == "no_published_rows_for_week" & snapshot$group_size != 0L) || any(snapshot$diagnostic_type != "no_published_rows_for_week" & snapshot$group_size < 1L)) {
    abort_quality_assessment("Quality snapshot provenance or group-size semantics are invalid.")
  }
  group_sizes <- dplyr::summarise(dplyr::group_by(snapshot, .data$diagnostic_group_id), observed_rows = sum(!is.na(.data$source_resource_id)), expected_size = dplyr::first(.data$group_size), .groups = "drop")
  if (any(group_sizes$observed_rows != group_sizes$expected_size) || anyDuplicated(snapshot[c("diagnostic_group_id", "source_resource_id", "source_row_number")], incomparables = FALSE)) {
    abort_quality_assessment("Quality snapshot group membership is invalid.")
  }
  invisible(TRUE)
}

#' Atomically publish a validated quality snapshot.
#'
#' @param snapshot Validated snapshot rows.
#' @param output_path Configured metadata output path.
#' @return Invisibly TRUE when publication succeeds.
publish_quality_snapshot <- function(snapshot, output_path) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(".argentina_dengue_quality_", dirname(output_path), ".csv")
  on.exit(unlink(temporary), add = TRUE)
  tryCatch(
    readr::write_csv(snapshot, temporary, na = ""),
    error = function(error) abort_quality_assessment(sprintf("Could not write quality snapshot temporary: %s", error$message))
  )
  if (!file.rename(temporary, output_path)) {
    abort_quality_assessment("Could not atomically publish harmonized-quality snapshot.")
  }
  invisible(TRUE)
}

#' Run harmonized-quality assessment from the project root.
#'
#' @return Invisibly TRUE on success.
main <- function() {
  config <- quality_assessment_config(read_project_config())
  structural_rows <- read_structural_artifact(config$input_path)
  snapshot <- build_quality_snapshot(structural_rows)
  validate_quality_snapshot(snapshot, structural_rows)
  message(sprintf("structural_rows=%s | resources=%s | schema_families=%s | quality_findings=%s", nrow(structural_rows), dplyr::n_distinct(structural_rows$source_resource_id), dplyr::n_distinct(structural_rows$source_schema_family), nrow(snapshot)))
  publish_quality_snapshot(snapshot, config$output_path)
  invisible(TRUE)
}

if (length(commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]) == 1L && basename(sub("^--file=", "", commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")])) == "05_assess_harmonized_quality.R") {
  main()
}
