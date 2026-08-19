###############################################################
# Argentina Dengue Analysis
# Script: 06_select_analysis_scope.R
# Purpose: Select a deterministic, row-preserving primary analysis scope.
# Inputs: project configuration and structural harmonization artifact.
# Output: selected published dengue rows in data/processed/.
###############################################################

structural_columns <- c(
  "source_resource_id", "source_local_filename", "source_row_number",
  "source_schema_family", "province_id", "province_name", "department_id",
  "department_name", "source_year", "source_week", "event",
  "source_age_group_id", "source_age_group_label", "source_case_count"
)

scope_columns <- c(
  "analysis_scope_schema_version", "analysis_scope_id", structural_columns
)

#' Stop analysis-scope selection with a contract-specific execution error.
#'
#' @param message Error message.
#' @return This function does not return.
abort_scope_selection <- function(message) {
  stop(message, call. = FALSE)
}

#' Read project configuration from its fixed bootstrap path.
#'
#' @return Parsed YAML configuration.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) {
    abort_scope_selection("Configuration file not found: config/project.yml")
  }
  tryCatch(
    yaml::read_yaml("config/project.yml"),
    error = function(error) abort_scope_selection(sprintf("Could not read configuration: %s", error$message))
  )
}

#' Retrieve one required scalar configuration string.
#'
#' @param config Parsed YAML configuration.
#' @param section First-level configuration section.
#' @param key Required key within the section.
#' @return Trimmed string.
required_string <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (is.null(value) || length(value) != 1L || !is.character(value) || is.na(value) || !nzchar(trimws(value))) {
    abort_scope_selection(sprintf("Missing or invalid configuration value: %s.%s", section, key))
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
    abort_scope_selection(sprintf("%s must be relative to the project root: %s", label, path))
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

#' Validate one configured source-year vector.
#'
#' @param values Configured source years.
#' @return Unique integer years.
scope_years <- function(values) {
  numeric_values <- suppressWarnings(as.numeric(unlist(values, use.names = FALSE)))
  if (!length(numeric_values) || any(is.na(numeric_values) | numeric_values != floor(numeric_values) | numeric_values < 1000 | numeric_values > 9999)) {
    abort_scope_selection("analysis_scope.primary.source_years must be non-empty years from 1000 through 9999.")
  }
  as.integer(unique(numeric_values))
}

#' Validate one configured event vector.
#'
#' @param values Configured event labels.
#' @return Unique non-empty event strings.
scope_events <- function(values) {
  events <- unlist(values, use.names = FALSE)
  if (!length(events) || !is.character(events) || any(is.na(events) | !nzchar(trimws(events)))) {
    abort_scope_selection("analysis_scope.primary.events must be non-empty event strings.")
  }
  unique(trimws(events))
}

#' Validate configuration used by analysis-scope selection.
#'
#' @param config Parsed YAML configuration.
#' @return Named list of validated paths and scope criteria.
scope_selection_config <- function(config) {
  paths <- list(
    processed_directory = required_string(config, "directories", "processed_data"),
    input_path = required_string(config, "artifacts", "canonical_resources_structural"),
    output_path = required_string(config, "artifacts", "primary_dengue_analysis_rows")
  )
  purrr::iwalk(paths, require_relative_path)
  if (!inside_directory(paths$input_path, paths$processed_directory) || !inside_directory(paths$output_path, paths$processed_directory)) {
    abort_scope_selection("Structural input and scope output must belong to the processed-data directory.")
  }
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  if (identical(
    normalizePath(file.path(root, paths$input_path), winslash = "/", mustWork = FALSE),
    normalizePath(file.path(root, paths$output_path), winslash = "/", mustWork = FALSE)
  )) {
    abort_scope_selection("Analysis-scope output must not replace its structural input.")
  }
  primary <- config$analysis_scope$primary
  if (is.null(primary) || !is.list(primary)) {
    abort_scope_selection("Missing analysis_scope.primary configuration.")
  }
  c(
    paths,
    list(
      scope_id = required_string(list(analysis_scope = primary), "analysis_scope", "scope_id"),
      source_years = scope_years(primary$source_years),
      events = scope_events(primary$events)
    )
  )
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
    abort_scope_selection(sprintf("Structural field %s is missing or not a decimal integer.", field))
  }
  parsed <- suppressWarnings(as.integer(values))
  if (any(is.na(parsed)) || any(parsed < minimum | parsed > maximum)) {
    abort_scope_selection(sprintf("Structural field %s is outside its contractual range.", field))
  }
  parsed
}

#' Read and validate the structural-harmonization artifact.
#'
#' @param path Configured structural input path.
#' @return Typed structural rows.
read_structural_artifact <- function(path) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) {
    abort_scope_selection(sprintf("Structural harmonization artifact is missing or not a regular file: %s", path))
  }
  rows <- tryCatch(
    readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())),
    error = function(error) abort_scope_selection(sprintf("Could not read structural harmonization artifact: %s", error$message))
  )
  if (!identical(names(rows), structural_columns) || nrow(readr::problems(rows))) {
    abort_scope_selection("Structural artifact does not satisfy structural_harmonization schema 1.0.0.")
  }
  required_text <- c("source_resource_id", "source_local_filename", "source_schema_family")
  if (!nrow(rows) || any(vapply(required_text, function(column) any(is.na(rows[[column]]) | !nzchar(rows[[column]])), logical(1)))) {
    abort_scope_selection("Structural artifact has missing required provenance or schema-family values.")
  }
  rows$source_row_number <- parse_contract_integer(rows$source_row_number, "source_row_number", 1L)
  rows$source_year <- parse_contract_integer(rows$source_year, "source_year", 1000L, 9999L)
  rows$source_week <- parse_contract_integer(rows$source_week, "source_week", 1L, 53L)
  rows$source_case_count <- parse_contract_integer(rows$source_case_count, "source_case_count", 0L)
  if (any(!rows$source_schema_family %in% c("generic_geography", "indec_residence_geography")) || anyDuplicated(rows[c("source_resource_id", "source_row_number")])) {
    abort_scope_selection("Structural artifact has an invalid schema family or non-unique source provenance.")
  }
  resource_shape <- dplyr::summarise(
    dplyr::group_by(rows, .data$source_resource_id),
    filenames = dplyr::n_distinct(.data$source_local_filename),
    families = dplyr::n_distinct(.data$source_schema_family),
    sequential_rows = identical(sort(.data$source_row_number), seq_len(dplyr::n())),
    .groups = "drop"
  )
  if (any(resource_shape$filenames != 1L | resource_shape$families != 1L | !resource_shape$sequential_rows)) {
    abort_scope_selection("Structural artifact violates per-resource filename, family, or row-number invariants.")
  }
  rows
}

#' Select structural rows solely from configured years and events.
#'
#' @param rows Validated structural rows.
#' @param source_years Configured source years.
#' @param events Configured event labels.
#' @return Selected structural rows in deterministic order.
select_scope_rows <- function(rows, source_years, events) {
  dplyr::arrange(
    dplyr::filter(rows, .data$source_year %in% source_years, .data$event %in% events),
    .data$source_resource_id,
    .data$source_row_number
  )
}

#' Verify that selection preserves exactly the intended structural rows.
#'
#' @param selected Selected structural rows.
#' @param source_rows Full validated structural rows.
#' @param config Validated scope configuration.
#' @return Invisibly TRUE when all invariants hold.
validate_selection_invariants <- function(selected, source_rows, config) {
  expected <- select_scope_rows(source_rows, config$source_years, config$events)
  if (!nrow(selected) || nrow(selected) != nrow(expected) || any(!selected$source_year %in% config$source_years) || any(!selected$event %in% config$events) || anyDuplicated(selected[c("source_resource_id", "source_row_number")]) || dplyr::n_distinct(selected$source_resource_id) != 1L) {
    abort_scope_selection("Analysis scope is empty or violates configured year, event, provenance, or single-resource invariants.")
  }
  for (column in structural_columns) {
    if (!identical(selected[[column]], expected[[column]])) {
      abort_scope_selection(sprintf("Selected values are not preserved for structural field: %s", column))
    }
  }
  invisible(TRUE)
}

#' Construct the contractual analysis-scope output schema.
#'
#' @param selected Validated selected structural rows.
#' @param scope_id Configured scope identifier.
#' @return Scope output tibble.
build_scope_output <- function(selected, scope_id) {
  output <- dplyr::mutate(
    selected,
    analysis_scope_schema_version = "1.0.0",
    analysis_scope_id = scope_id,
    .before = 1L
  )
  output[, scope_columns]
}

#' Validate the completed output before atomic publication.
#'
#' @param output Candidate analysis-scope output.
#' @param selected Validated selected structural rows.
#' @param config Validated scope configuration.
#' @return Invisibly TRUE when valid.
validate_scope_output <- function(output, selected, config) {
  if (!identical(names(output), scope_columns) || any(output$analysis_scope_schema_version != "1.0.0") || any(output$analysis_scope_id != config$scope_id) || anyDuplicated(output[c("source_resource_id", "source_row_number")]) || !identical(output[structural_columns], selected[structural_columns])) {
    abort_scope_selection("Analysis-scope output schema or preservation invariants are invalid.")
  }
  invisible(TRUE)
}

#' Atomically publish a validated analysis-scope artifact.
#'
#' @param output Validated scope output.
#' @param output_path Configured output path.
#' @return Invisibly TRUE when publication succeeds.
publish_scope_output <- function(output, output_path) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(".argentina_dengue_analysis_scope_", dirname(output_path), ".csv")
  on.exit(unlink(temporary), add = TRUE)
  tryCatch(
    readr::write_csv(output, temporary, na = ""),
    error = function(error) abort_scope_selection(sprintf("Could not write analysis-scope temporary: %s", error$message))
  )
  if (!file.rename(temporary, output_path)) {
    abort_scope_selection("Could not atomically publish primary analysis scope.")
  }
  invisible(TRUE)
}

#' Run primary analysis-scope selection from the project root.
#'
#' @return Invisibly TRUE on success.
main <- function() {
  config <- scope_selection_config(read_project_config())
  source_rows <- read_structural_artifact(config$input_path)
  selected <- select_scope_rows(source_rows, config$source_years, config$events)
  validate_selection_invariants(selected, source_rows, config)
  output <- build_scope_output(selected, config$scope_id)
  validate_scope_output(output, selected, config)
  message(sprintf("scope_id=%s | selected_rows=%s | source_resources=%s | source_case_count_sum=%s", config$scope_id, nrow(selected), dplyr::n_distinct(selected$source_resource_id), sum(selected$source_case_count)))
  publish_scope_output(output, config$output_path)
  invisible(TRUE)
}

if (length(commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]) == 1L && basename(sub("^--file=", "", commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")])) == "06_select_analysis_scope.R") {
  main()
}
