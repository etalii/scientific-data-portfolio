###############################################################
# Argentina Dengue Analysis
# Script: 07_build_analysis_tables.R
# Purpose: Derive deterministic published-count analysis tables.
# Inputs: project configuration and primary analysis-scope artifact.
# Outputs: four reconciled analysis tables in data/processed/.
###############################################################

scope_columns <- c(
  "analysis_scope_schema_version", "analysis_scope_id", "source_resource_id",
  "source_local_filename", "source_row_number", "source_schema_family",
  "province_id", "province_name", "department_id", "department_name",
  "source_year", "source_week", "event", "source_age_group_id",
  "source_age_group_label", "source_case_count"
)

table_columns <- list(
  weekly_national = c(
    "analysis_table_schema_version", "analysis_scope_id", "source_resource_id",
    "source_year", "source_week", "published_row_count", "published_case_count"
  ),
  province_summary = c(
    "analysis_table_schema_version", "analysis_scope_id", "source_resource_id",
    "source_year", "province_id", "province_name", "published_row_count",
    "published_case_count", "published_case_share"
  ),
  weekly_province = c(
    "analysis_table_schema_version", "analysis_scope_id", "source_resource_id",
    "source_year", "source_week", "province_id", "province_name",
    "published_row_count", "published_case_count"
  ),
  age_group_summary = c(
    "analysis_table_schema_version", "analysis_scope_id", "source_resource_id",
    "source_year", "source_age_group_id", "source_age_group_label",
    "published_row_count", "published_case_count", "published_case_share"
  )
)

share_tolerance <- 1e-12

#' Stop analysis-table derivation with a contract-specific execution error.
#'
#' @param message Error message.
#' @return This function does not return.
abort_table_derivation <- function(message) {
  stop(message, call. = FALSE)
}

#' Read project configuration from its fixed bootstrap path.
#'
#' @return Parsed YAML configuration.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) {
    abort_table_derivation("Configuration file not found: config/project.yml")
  }
  tryCatch(
    yaml::read_yaml("config/project.yml"),
    error = function(error) abort_table_derivation(sprintf("Could not read configuration: %s", error$message))
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
    abort_table_derivation(sprintf("Missing or invalid configuration value: %s.%s", section, key))
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
    abort_table_derivation(sprintf("%s must be relative to the project root: %s", label, path))
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

#' Validate paths required by analysis-table derivation.
#'
#' @param config Parsed YAML configuration.
#' @return Named list of input and output paths.
table_derivation_config <- function(config) {
  paths <- list(
    processed_directory = required_string(config, "directories", "processed_data"),
    input_path = required_string(config, "artifacts", "primary_dengue_analysis_rows"),
    weekly_national_path = required_string(config, "artifacts", "analysis_weekly_national"),
    province_summary_path = required_string(config, "artifacts", "analysis_province_summary"),
    weekly_province_path = required_string(config, "artifacts", "analysis_weekly_province"),
    age_group_summary_path = required_string(config, "artifacts", "analysis_age_group_summary")
  )
  purrr::iwalk(paths, require_relative_path)
  if (any(!vapply(paths[-1L], inside_directory, logical(1), directory = paths$processed_directory))) {
    abort_table_derivation("Analysis-table input and outputs must belong to the processed-data directory.")
  }
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  resolved <- vapply(paths[-1L], function(path) normalizePath(file.path(root, path), winslash = "/", mustWork = FALSE), character(1))
  if (anyDuplicated(resolved) || any(resolved[-1L] == resolved[[1L]])) {
    abort_table_derivation("Analysis-table outputs must be distinct and must not replace the input scope.")
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
    abort_table_derivation(sprintf("Scope field %s is missing or not a decimal integer.", field))
  }
  parsed <- suppressWarnings(as.integer(values))
  if (any(is.na(parsed)) || any(parsed < minimum | parsed > maximum)) {
    abort_table_derivation(sprintf("Scope field %s is outside its contractual range.", field))
  }
  parsed
}

#' Read and validate the primary analysis-scope artifact.
#'
#' @param path Configured primary scope path.
#' @return Typed scope rows.
read_primary_scope <- function(path) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) {
    abort_table_derivation(sprintf("Primary analysis scope is missing or not a regular file: %s", path))
  }
  rows <- tryCatch(
    readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())),
    error = function(error) abort_table_derivation(sprintf("Could not read primary analysis scope: %s", error$message))
  )
  if (!identical(names(rows), scope_columns) || nrow(readr::problems(rows)) || !nrow(rows) || any(rows$analysis_scope_schema_version != "1.0.0")) {
    abort_table_derivation("Primary analysis scope does not satisfy analysis_scope_selection schema 1.0.0.")
  }
  required_text <- c("analysis_scope_id", "source_resource_id", "source_local_filename", "source_schema_family")
  if (any(vapply(required_text, function(column) any(is.na(rows[[column]]) | !nzchar(rows[[column]])), logical(1)))) {
    abort_table_derivation("Primary analysis scope has missing required scope or provenance values.")
  }
  rows$source_row_number <- parse_contract_integer(rows$source_row_number, "source_row_number", 1L)
  rows$source_year <- parse_contract_integer(rows$source_year, "source_year", 1000L, 9999L)
  rows$source_week <- parse_contract_integer(rows$source_week, "source_week", 1L, 53L)
  rows$source_case_count <- parse_contract_integer(rows$source_case_count, "source_case_count", 0L)
  if (dplyr::n_distinct(rows$analysis_scope_id) != 1L || dplyr::n_distinct(rows$source_resource_id) != 1L || dplyr::n_distinct(rows$source_year) != 1L || dplyr::n_distinct(rows$event) != 1L || any(is.na(rows$event) | !nzchar(rows$event)) || anyDuplicated(rows[c("source_resource_id", "source_row_number")])) {
    abort_table_derivation("Primary analysis scope must contain exactly one scope, resource, year, event, and unique source provenance.")
  }
  rows
}

#' Abort when a source identifier maps ambiguously to a source label.
#'
#' @param rows Scope rows.
#' @param id_column Source identifier column.
#' @param label_column Source label column.
#' @param relationship Description for the error message.
#' @return Invisibly TRUE when mapping is unambiguous.
require_unambiguous_mapping <- function(rows, id_column, label_column, relationship) {
  conflicts <- dplyr::summarise(
    dplyr::group_by(dplyr::filter(rows, !is.na(.data[[id_column]])), .data[[id_column]]),
    label_count = dplyr::n_distinct(.data[[label_column]]),
    .groups = "drop"
  )
  if (any(conflicts$label_count > 1L)) {
    abort_table_derivation(sprintf("Primary analysis scope has an ambiguous %s mapping.", relationship))
  }
  invisible(TRUE)
}

#' Parse source age-group IDs only for contractual ordering.
#'
#' @param values Source age-group IDs retained as text in output.
#' @return Integer ordering vector.
age_group_order <- function(values) {
  parse_contract_integer(values, "source_age_group_id", 0L)
}

#' Add common table provenance columns to one aggregation.
#'
#' @param table Aggregated tibble.
#' @param scope_rows Validated primary scope rows.
#' @return Tibble with common fields preceding aggregate dimensions.
add_table_provenance <- function(table, scope_rows) {
  dplyr::mutate(
    table,
    analysis_table_schema_version = "1.0.0",
    analysis_scope_id = scope_rows$analysis_scope_id[[1]],
    source_resource_id = scope_rows$source_resource_id[[1]],
    .before = 1L
  )
}

#' Add an unrounded published-count share to one aggregate table.
#'
#' @param table Aggregated tibble.
#' @param total_published_cases Full-scope case-count denominator.
#' @return Tibble with published_case_share.
add_published_case_share <- function(table, total_published_cases) {
  dplyr::mutate(
    table,
    published_case_share = if (total_published_cases == 0) NA_real_ else .data$published_case_count / total_published_cases
  )
}

#' Build the national weekly aggregation.
#'
#' @param rows Validated primary scope rows.
#' @return National weekly table.
build_weekly_national <- function(rows) {
  result <- dplyr::summarise(
    dplyr::group_by(rows, .data$source_year, .data$source_week),
    published_row_count = dplyr::n(),
    published_case_count = sum(.data$source_case_count),
    .groups = "drop"
  )
  result <- add_table_provenance(result, rows)
  result <- dplyr::arrange(result, .data$source_year, .data$source_week)
  result[, table_columns$weekly_national]
}

#' Build the provincial aggregation, retaining all published categories.
#'
#' @param rows Validated primary scope rows.
#' @return Provincial summary table.
build_province_summary <- function(rows) {
  require_unambiguous_mapping(rows, "province_id", "province_name", "province ID to name")
  result <- dplyr::summarise(
    dplyr::group_by(rows, .data$source_year, .data$province_id, .data$province_name),
    published_row_count = dplyr::n(),
    published_case_count = sum(.data$source_case_count),
    .groups = "drop"
  )
  result <- add_published_case_share(result, sum(rows$source_case_count))
  result <- add_table_provenance(result, rows)
  result <- dplyr::arrange(result, .data$source_year, .data$province_id, .data$province_name)
  result[, table_columns$province_summary]
}

#' Build the published province-week aggregation without completing a grid.
#'
#' @param rows Validated primary scope rows.
#' @return Provincial weekly table.
build_weekly_province <- function(rows) {
  result <- dplyr::summarise(
    dplyr::group_by(rows, .data$source_year, .data$source_week, .data$province_id, .data$province_name),
    published_row_count = dplyr::n(),
    published_case_count = sum(.data$source_case_count),
    .groups = "drop"
  )
  result <- add_table_provenance(result, rows)
  result <- dplyr::arrange(result, .data$source_year, .data$source_week, .data$province_id, .data$province_name)
  result[, table_columns$weekly_province]
}

#' Build the source-age-group aggregation without recoding labels.
#'
#' @param rows Validated primary scope rows.
#' @return Source-age-group summary table.
build_age_group_summary <- function(rows) {
  require_unambiguous_mapping(rows, "source_age_group_id", "source_age_group_label", "source age-group ID to label")
  result <- dplyr::summarise(
    dplyr::group_by(rows, .data$source_year, .data$source_age_group_id, .data$source_age_group_label),
    published_row_count = dplyr::n(),
    published_case_count = sum(.data$source_case_count),
    .groups = "drop"
  )
  result <- add_published_case_share(result, sum(rows$source_case_count))
  result <- add_table_provenance(result, rows)
  result$.age_group_order <- age_group_order(result$source_age_group_id)
  result <- dplyr::arrange(result, .data$source_year, .data$.age_group_order, .data$source_age_group_label)
  result$.age_group_order <- NULL
  result[, table_columns$age_group_summary]
}

#' Verify deterministic ordering of one completed table.
#'
#' @param table Completed table.
#' @param table_name Contractual table name.
#' @return Invisibly TRUE when ordering is valid.
validate_table_order <- function(table, table_name) {
  ordered <- switch(
    table_name,
    weekly_national = dplyr::arrange(table, .data$source_year, .data$source_week),
    province_summary = dplyr::arrange(table, .data$source_year, .data$province_id, .data$province_name),
    weekly_province = dplyr::arrange(table, .data$source_year, .data$source_week, .data$province_id, .data$province_name),
    age_group_summary = {
      ordering <- age_group_order(table$source_age_group_id)
      dplyr::arrange(dplyr::mutate(table, .age_group_order = ordering), .data$source_year, .data$.age_group_order, .data$source_age_group_label) |> dplyr::select(-dplyr::all_of(".age_group_order"))
    },
    abort_table_derivation(sprintf("Unknown analysis table: %s", table_name))
  )
  if (!identical(table, ordered)) {
    abort_table_derivation(sprintf("Analysis table has a non-deterministic order: %s", table_name))
  }
  invisible(TRUE)
}

#' Validate one completed table against full-scope reconciliation invariants.
#'
#' @param table Completed table.
#' @param table_name Contractual table name.
#' @param scope_rows Validated input rows.
#' @return Invisibly TRUE when valid.
validate_analysis_table <- function(table, table_name, scope_rows) {
  columns <- table_columns[[table_name]]
  if (is.null(columns) || !identical(names(table), columns) || !nrow(table) || any(table$analysis_table_schema_version != "1.0.0") || any(table$analysis_scope_id != scope_rows$analysis_scope_id[[1]]) || any(table$source_resource_id != scope_rows$source_resource_id[[1]]) || any(table$source_year != scope_rows$source_year[[1]])) {
    abort_table_derivation(sprintf("Analysis table schema or common provenance is invalid: %s", table_name))
  }
  key_columns <- switch(
    table_name,
    weekly_national = c("analysis_scope_id", "source_resource_id", "source_year", "source_week"),
    province_summary = c("analysis_scope_id", "source_resource_id", "source_year", "province_id", "province_name"),
    weekly_province = c("analysis_scope_id", "source_resource_id", "source_year", "source_week", "province_id", "province_name"),
    age_group_summary = c("analysis_scope_id", "source_resource_id", "source_year", "source_age_group_id", "source_age_group_label")
  )
  if (anyDuplicated(table[key_columns]) || any(is.na(table$published_row_count) | table$published_row_count < 1 | table$published_row_count != floor(table$published_row_count)) || any(is.na(table$published_case_count) | table$published_case_count < 0 | table$published_case_count != floor(table$published_case_count)) || sum(table$published_row_count) != nrow(scope_rows) || sum(table$published_case_count) != sum(scope_rows$source_case_count)) {
    abort_table_derivation(sprintf("Analysis table key or reconciliation invariant failed: %s", table_name))
  }
  if ("published_case_share" %in% names(table)) {
    denominator <- sum(scope_rows$source_case_count)
    valid_share <- if (denominator == 0) all(is.na(table$published_case_share)) else all(!is.na(table$published_case_share) & table$published_case_share >= 0 & table$published_case_share <= 1) && abs(sum(table$published_case_share) - 1) <= share_tolerance
    if (!valid_share) {
      abort_table_derivation(sprintf("Analysis table share invariant failed: %s", table_name))
    }
  }
  validate_table_order(table, table_name)
  invisible(TRUE)
}

#' Write every completed table to controlled temporary files before publication.
#'
#' @param tables Named list of validated tables.
#' @param paths Named list of final artifact paths.
#' @return Named vector of temporary paths.
write_table_temporaries <- function(tables, paths) {
  temporary_paths <- purrr::imap_chr(paths, function(path, table_name) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    tempfile(paste0(".argentina_dengue_", table_name, "_"), dirname(path), ".csv")
  })
  tryCatch(
    purrr::iwalk(tables, function(table, table_name) readr::write_csv(table, temporary_paths[[table_name]], na = "")),
    error = function(error) abort_table_derivation(sprintf("Could not write temporary analysis table: %s", error$message))
  )
  temporary_paths
}

#' Atomically publish every already-written analysis table.
#'
#' @param temporary_paths Named temporary paths.
#' @param final_paths Named final artifact paths.
#' @return Invisibly TRUE when all publications succeed.
publish_analysis_tables <- function(temporary_paths, final_paths) {
  purrr::iwalk(final_paths, function(path, table_name) {
    if (!file.rename(temporary_paths[[table_name]], path)) {
      abort_table_derivation(sprintf("Could not atomically publish analysis table: %s", table_name))
    }
  })
  invisible(TRUE)
}

#' Run analysis-table derivation from the project root.
#'
#' @return Invisibly TRUE on success.
main <- function() {
  config <- table_derivation_config(read_project_config())
  scope_rows <- read_primary_scope(config$input_path)
  tables <- list(
    weekly_national = build_weekly_national(scope_rows),
    province_summary = build_province_summary(scope_rows),
    weekly_province = build_weekly_province(scope_rows),
    age_group_summary = build_age_group_summary(scope_rows)
  )
  purrr::iwalk(tables, validate_analysis_table, scope_rows = scope_rows)
  final_paths <- list(
    weekly_national = config$weekly_national_path,
    province_summary = config$province_summary_path,
    weekly_province = config$weekly_province_path,
    age_group_summary = config$age_group_summary_path
  )
  temporary_paths <- write_table_temporaries(tables, final_paths)
  on.exit(unlink(temporary_paths), add = TRUE)
  publish_analysis_tables(temporary_paths, final_paths)
  message(sprintf("scope_id=%s | source_resource_id=%s | source_year=%s | input_rows=%s | published_case_count=%s | weekly_national=%s | province_summary=%s | weekly_province=%s | age_group_summary=%s", scope_rows$analysis_scope_id[[1]], scope_rows$source_resource_id[[1]], scope_rows$source_year[[1]], nrow(scope_rows), sum(scope_rows$source_case_count), nrow(tables$weekly_national), nrow(tables$province_summary), nrow(tables$weekly_province), nrow(tables$age_group_summary)))
  invisible(TRUE)
}

if (length(commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]) == 1L && basename(sub("^--file=", "", commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")])) == "07_build_analysis_tables.R") {
  main()
}
