###############################################################
# Argentina Dengue Analysis
# Script: 12_build_multiyear_analysis_tables.R
# Purpose: Derive descriptive tables from multiyear Dengue scopes.
###############################################################

scope_columns <- c("multiyear_scope_schema_version", "analysis_scope_id", "source_resource_id", "source_local_filename", "source_row_number", "source_schema_family", "province_id", "province_name", "department_id", "department_name", "source_year", "source_week", "event", "source_age_group_id", "source_age_group_label", "source_case_count")

#' Abort multiyear table derivation with a contract-specific error.
abort_multiyear_tables <- function(message) stop(message, call. = FALSE)

#' Read project configuration from its bootstrap path.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) abort_multiyear_tables("Configuration file not found: config/project.yml")
  yaml::read_yaml("config/project.yml")
}

#' Return one required project-relative artifact path.
artifact_path <- function(config, key) {
  path <- config$artifacts[[key]]
  if (is.null(path) || length(path) != 1L || !is.character(path) || !nzchar(path) || grepl("^(/|[[:alpha:]]:[/\\\\])", path)) abort_multiyear_tables(sprintf("Invalid artifacts.%s path.", key))
  path
}

#' Read and validate the multiyear scope artifact.
read_scope <- function(path) {
  rows <- tryCatch(readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())), error = function(error) abort_multiyear_tables(error$message))
  if (!identical(names(rows), scope_columns) || !nrow(rows) || nrow(readr::problems(rows)) || any(rows$multiyear_scope_schema_version != "1.0.0") || any(rows$event != "Dengue")) abort_multiyear_tables("Input does not satisfy multiyear_dengue_scope v1.0.0.")
  for (field in c("source_row_number", "source_year", "source_week", "source_case_count")) {
    if (any(is.na(rows[[field]]) | !grepl("^[0-9]+$", rows[[field]]))) abort_multiyear_tables(sprintf("Invalid numeric scope field: %s", field))
    rows[[field]] <- as.integer(rows[[field]])
  }
  if (anyDuplicated(rows[c("source_resource_id", "source_row_number")])) abort_multiyear_tables("Scope provenance is not unique.")
  rows
}

#' Atomically publish one regenerated table.
publish_table <- function(rows, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(".multiyear_table_", tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(rows, temporary, na = "")
  if (!file.rename(temporary, path)) abort_multiyear_tables(sprintf("Could not publish %s", path))
}

#' Add the table contract version to an aggregate.
add_version <- function(rows) dplyr::mutate(rows, multiyear_analysis_table_schema_version = "1.0.0", .before = 1L)

#' Build the four descriptive multiyear aggregates.
build_tables <- function(rows) {
  totals <- dplyr::summarise(dplyr::group_by(rows, .data$analysis_scope_id, .data$source_resource_id, .data$source_year), total = sum(.data$source_case_count), .groups = "drop")
  weekly <- rows |> dplyr::group_by(.data$analysis_scope_id, .data$source_resource_id, .data$source_year, .data$source_week) |> dplyr::summarise(published_row_count = dplyr::n(), published_case_count = sum(.data$source_case_count), .groups = "drop") |> dplyr::arrange(.data$source_year, .data$source_week) |> add_version()
  province <- rows |> dplyr::group_by(.data$analysis_scope_id, .data$source_resource_id, .data$source_year, .data$province_id, .data$province_name) |> dplyr::summarise(published_row_count = dplyr::n(), published_case_count = sum(.data$source_case_count), .groups = "drop") |> dplyr::left_join(totals, by = c("analysis_scope_id", "source_resource_id", "source_year")) |> dplyr::mutate(published_case_share = ifelse(.data$total == 0L, NA_real_, .data$published_case_count / .data$total)) |> dplyr::select(-total) |> dplyr::arrange(.data$source_year, .data$province_id, .data$province_name) |> add_version()
  weekly_province <- rows |> dplyr::group_by(.data$analysis_scope_id, .data$source_resource_id, .data$source_year, .data$source_week, .data$province_id, .data$province_name) |> dplyr::summarise(published_row_count = dplyr::n(), published_case_count = sum(.data$source_case_count), .groups = "drop") |> dplyr::arrange(.data$source_year, .data$source_week, .data$province_id, .data$province_name) |> add_version()
  age <- rows |> dplyr::group_by(.data$analysis_scope_id, .data$source_resource_id, .data$source_year, .data$source_age_group_id, .data$source_age_group_label) |> dplyr::summarise(published_row_count = dplyr::n(), published_case_count = sum(.data$source_case_count), .groups = "drop") |> dplyr::left_join(totals, by = c("analysis_scope_id", "source_resource_id", "source_year")) |> dplyr::mutate(published_case_share = ifelse(.data$total == 0L, NA_real_, .data$published_case_count / .data$total)) |> dplyr::select(-total) |> dplyr::arrange(.data$source_year, .data$source_age_group_id, .data$source_age_group_label) |> add_version()
  list(weekly = weekly, province = province, weekly_province = weekly_province, age = age)
}

#' Build, reconcile, and publish multiyear descriptive tables.
main <- function() {
  config <- read_project_config(); rows <- read_scope(artifact_path(config, "multiyear_dengue_scopes")); tables <- build_tables(rows)
  total_rows <- nrow(rows); total_cases <- sum(rows$source_case_count)
  for (table in tables) if (sum(table$published_row_count) != total_rows || sum(table$published_case_count) != total_cases) abort_multiyear_tables("Aggregate reconciliation failed.")
  publish_table(tables$weekly, artifact_path(config, "multiyear_dengue_weekly_national")); publish_table(tables$province, artifact_path(config, "multiyear_dengue_province_summary")); publish_table(tables$weekly_province, artifact_path(config, "multiyear_dengue_weekly_province")); publish_table(tables$age, artifact_path(config, "multiyear_dengue_age_summary"))
  invisible(tables)
}

if (sys.nframe() == 0L) main()
