###############################################################
# Argentina Dengue Analysis
# Script: 11_build_multiyear_dengue_scopes.R
# Purpose: Build row-preserving Dengue scopes for configured canonical years.
###############################################################

structural_columns <- c("source_resource_id", "source_local_filename", "source_row_number", "source_schema_family", "province_id", "province_name", "department_id", "department_name", "source_year", "source_week", "event", "source_age_group_id", "source_age_group_label", "source_case_count")
scope_columns <- c("multiyear_scope_schema_version", "analysis_scope_id", structural_columns)

#' Abort multiyear scope construction with a clear contractual error.
abort_multiyear_scope <- function(message) stop(message, call. = FALSE)

#' Read the centrally configured project file.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) abort_multiyear_scope("Configuration file not found: config/project.yml")
  tryCatch(yaml::read_yaml("config/project.yml"), error = function(error) abort_multiyear_scope(error$message))
}

#' Require one non-empty project-relative configuration value.
required_path <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (is.null(value) || length(value) != 1L || !is.character(value) || is.na(value) || !nzchar(value) || grepl("^(/|[[:alpha:]]:[/\\\\])", value)) abort_multiyear_scope(sprintf("Invalid configuration value: %s.%s", section, key))
  value
}

#' Validate and read structural harmonization rows.
read_structural_rows <- function(path) {
  rows <- tryCatch(readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())), error = function(error) abort_multiyear_scope(sprintf("Could not read structural artifact: %s", error$message)))
  if (!identical(names(rows), structural_columns) || !nrow(rows) || nrow(readr::problems(rows))) abort_multiyear_scope("Structural artifact does not satisfy structural_harmonization v1.0.0 schema.")
  for (field in c("source_row_number", "source_year", "source_week", "source_case_count")) {
    if (any(is.na(rows[[field]]) | !grepl("^[0-9]+$", rows[[field]]))) abort_multiyear_scope(sprintf("Invalid structural numeric field: %s", field))
    rows[[field]] <- as.integer(rows[[field]])
  }
  if (any(rows$source_week < 1L | rows$source_week > 53L) || anyDuplicated(rows[c("source_resource_id", "source_row_number")])) abort_multiyear_scope("Structural rows have invalid weeks or duplicate provenance.")
  rows
}

#' Atomically write one controlled CSV artifact.
publish_csv <- function(rows, path) {
  directory <- dirname(path); dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(".multiyear_scope_", tmpdir = directory, fileext = ".tmp")
  on.exit(unlink(temporary), add = TRUE)
  tryCatch(readr::write_csv(rows, temporary, na = ""), error = function(error) abort_multiyear_scope(sprintf("Could not write scope artifact: %s", error$message)))
  if (!file.rename(temporary, path)) abort_multiyear_scope(sprintf("Could not atomically publish scope artifact: %s", path))
}

#' Build and validate the configured multiyear Dengue scopes.
main <- function() {
  config <- read_project_config()
  input <- required_path(config, "artifacts", "canonical_resources_structural")
  output <- required_path(config, "artifacts", "multiyear_dengue_scopes")
  years <- as.integer(unlist(config$multiyear_scope$source_years, use.names = FALSE))
  event <- config$multiyear_scope$event
  if (!length(years) || any(is.na(years)) || !is.character(event) || length(event) != 1L || !nzchar(event)) abort_multiyear_scope("Invalid multiyear_scope configuration.")
  rows <- read_structural_rows(input)
  selected <- dplyr::filter(rows, .data$source_year %in% .env$years, .data$event == .env$event)
  shape <- dplyr::summarise(dplyr::group_by(selected, .data$source_year), resources = dplyr::n_distinct(.data$source_resource_id), rows = dplyr::n(), .groups = "drop")
  if (nrow(shape) != length(unique(years)) || any(shape$resources != 1L | shape$rows == 0L)) abort_multiyear_scope("Each configured multiyear Dengue scope must be non-empty and contain exactly one resource.")
  selected <- dplyr::arrange(selected, .data$source_year, .data$source_resource_id, .data$source_row_number)
  output_rows <- dplyr::mutate(selected, multiyear_scope_schema_version = "1.0.0", analysis_scope_id = paste0("dengue_", .data$source_year), .before = 1L)[, scope_columns]
  if (anyDuplicated(output_rows[c("source_resource_id", "source_row_number")]) || !identical(output_rows[structural_columns], selected[structural_columns])) abort_multiyear_scope("Scope preservation invariant failed.")
  publish_csv(output_rows, output)
  invisible(output_rows)
}

if (sys.nframe() == 0L) main()
