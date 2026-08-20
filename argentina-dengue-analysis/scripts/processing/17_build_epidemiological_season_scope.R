###############################################################
# Argentina Dengue Analysis
# Script: 17_build_epidemiological_season_scope.R
# Purpose: Build a deterministic source-week Dengue season scope from C.11.
###############################################################

c11_columns <- c(
  "multiyear_scope_schema_version", "analysis_scope_id", "source_resource_id",
  "source_local_filename", "source_row_number", "source_schema_family",
  "province_id", "province_name", "department_id", "department_name",
  "source_year", "source_week", "event", "source_age_group_id",
  "source_age_group_label", "source_case_count"
)
season_columns <- c(
  "season_scope_schema_version", "season_scope_id", "season_label",
  "season_week_index", c11_columns
)
snapshot_columns <- c(
  "season_scope_snapshot_schema_version", "season_scope_id", "season_label",
  "expected_season_week_count", "observed_season_week_count",
  "missing_season_week_count", "unexpected_season_week_count",
  "season_week_coverage_status", "source_schema_family",
  "source_resource_count", "source_resource_ids", "season_row_count",
  "season_published_case_count"
)

#' Abort season-scope construction with a contractual error.
abort_season_scope <- function(message) stop(message, call. = FALSE)

#' Read the project configuration from its fixed project-root location.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) abort_season_scope("Configuration file not found: config/project.yml")
  tryCatch(yaml::read_yaml("config/project.yml"), error = function(error) abort_season_scope(error$message))
}

#' Require one non-empty project-relative configured path.
required_path <- function(config, key, directory) {
  path <- config$artifacts[[key]]
  if (is.null(path) || length(path) != 1L || !is.character(path) || is.na(path) ||
      !nzchar(path) || grepl("^(/|[[:alpha:]]:[/\\])", path) ||
      !startsWith(path, paste0(directory, "/"))) {
    abort_season_scope(sprintf("Invalid artifact path: artifacts.%s", key))
  }
  path
}

#' Convert a configured scalar to a strict integer.
strict_integer <- function(value, field) {
  numeric_value <- suppressWarnings(as.numeric(value))
  integer_value <- suppressWarnings(as.integer(numeric_value))
  if (length(value) != 1L || is.na(numeric_value) || !is.finite(numeric_value) ||
      numeric_value != integer_value) abort_season_scope(sprintf("Invalid integer configuration: %s", field))
  integer_value
}

#' Build the ordered, unique expected source-year/week tuples from configuration.
build_expected_tuples <- function(season_config) {
  if (is.null(season_config$scope_id) || !is.character(season_config$scope_id) ||
      length(season_config$scope_id) != 1L || !nzchar(season_config$scope_id) ||
      is.null(season_config$season_label) || !is.character(season_config$season_label) ||
      length(season_config$season_label) != 1L || !nzchar(season_config$season_label) ||
      is.null(season_config$event) || !is.character(season_config$event) ||
      length(season_config$event) != 1L || !nzchar(season_config$event) ||
      is.null(season_config$segments) || !length(season_config$segments)) {
    abort_season_scope("Invalid epidemiological_season configuration.")
  }

  tuples <- lapply(seq_along(season_config$segments), function(index) {
    segment <- season_config$segments[[index]]
    year <- strict_integer(segment$source_year, sprintf("segments[%d].source_year", index))
    week_start <- strict_integer(segment$week_start, sprintf("segments[%d].week_start", index))
    week_end <- strict_integer(segment$week_end, sprintf("segments[%d].week_end", index))
    if (year < 1000L || year > 9999L || week_start < 1L || week_end > 53L || week_start > week_end) {
      abort_season_scope(sprintf("Invalid epidemiological season segment: %d", index))
    }
    tibble::tibble(source_year = year, source_week = seq.int(week_start, week_end))
  })
  expected <- dplyr::bind_rows(tuples) |>
    dplyr::mutate(season_week_index = dplyr::row_number())
  if (anyDuplicated(expected[c("source_year", "source_week")])) {
    abort_season_scope("Epidemiological season configuration generates duplicate tuples.")
  }
  expected
}

#' Read C.11 rows and validate the schema and source-row numeric fields.
read_c11_rows <- function(path) {
  rows <- tryCatch(
    readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())),
    error = function(error) abort_season_scope(sprintf("Could not read C.11 artifact: %s", error$message))
  )
  if (!identical(names(rows), c11_columns) || !nrow(rows) || nrow(readr::problems(rows))) {
    abort_season_scope("Input does not satisfy multiyear_dengue_scope v1.0.0 schema.")
  }
  for (field in c("source_row_number", "source_year", "source_week", "source_case_count")) {
    if (any(is.na(rows[[field]]) | !grepl("^[0-9]+$", rows[[field]]))) {
      abort_season_scope(sprintf("Invalid C.11 numeric field: %s", field))
    }
    rows[[field]] <- as.integer(rows[[field]])
  }
  if (any(rows$source_week < 1L | rows$source_week > 53L) ||
      anyDuplicated(rows[c("source_resource_id", "source_row_number")]) ||
      any(rows$multiyear_scope_schema_version != "1.0.0")) {
    abort_season_scope("C.11 source-row invariants failed.")
  }
  rows
}

#' Atomically write one controlled CSV artifact.
publish_csv <- function(rows, path, prefix) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(prefix, tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(temporary), add = TRUE)
  tryCatch(readr::write_csv(rows, temporary, na = ""), error = function(error) abort_season_scope(error$message))
  if (!file.rename(temporary, path)) abort_season_scope(sprintf("Could not publish artifact: %s", path))
}

#' Build, validate, and publish the configured epidemiological season scope.
main <- function() {
  config <- read_project_config()
  input_path <- required_path(config, "multiyear_dengue_scopes", config$directories$processed_data)
  output_path <- required_path(config, "epidemiological_season_rows", config$directories$processed_data)
  snapshot_path <- required_path(config, "epidemiological_season_scope_snapshot", config$directories$metadata)
  expected <- build_expected_tuples(config$epidemiological_season)
  rows <- read_c11_rows(input_path)
  season_config <- config$epidemiological_season

  candidate <- rows |>
    dplyr::filter(.data$event == .env$season_config$event) |>
    dplyr::inner_join(expected, by = c("source_year", "source_week"))
  observed <- dplyr::distinct(candidate, source_year, source_week)
  missing <- dplyr::anti_join(expected[c("source_year", "source_week")], observed, by = c("source_year", "source_week"))
  unexpected <- dplyr::anti_join(observed, expected[c("source_year", "source_week")], by = c("source_year", "source_week"))
  coverage_status <- if (nrow(unexpected)) "unexpected_week_set" else if (nrow(missing)) "incomplete_expected_week_set" else "complete_expected_week_set"

  if (!identical(coverage_status, "complete_expected_week_set")) {
    abort_season_scope(sprintf("Season coverage is not exact: status=%s, missing=%d, unexpected=%d.", coverage_status, nrow(missing), nrow(unexpected)))
  }
  families <- sort(unique(candidate$source_schema_family))
  if (length(families) != 1L) abort_season_scope(sprintf("Season scope spans multiple structural families: %s", paste(families, collapse = "|")))
  if (any(candidate$event != season_config$event) || nrow(candidate) == 0L) {
    abort_season_scope("Season selection has an invalid event or is empty.")
  }

  output_rows <- candidate |>
    dplyr::arrange(season_week_index, source_resource_id, source_row_number) |>
    dplyr::mutate(
      season_scope_schema_version = "1.0.0",
      season_scope_id = season_config$scope_id,
      season_label = season_config$season_label,
      .before = 1L
    ) |>
    dplyr::select(dplyr::all_of(season_columns))
  expected_source_rows <- rows |>
    dplyr::filter(.data$event == .env$season_config$event) |>
    dplyr::semi_join(expected, by = c("source_year", "source_week"))
  if (nrow(output_rows) != nrow(expected_source_rows) ||
      sum(output_rows$source_case_count) != sum(expected_source_rows$source_case_count) ||
      anyDuplicated(output_rows[c("source_resource_id", "source_row_number")]) ||
      !identical(dplyr::arrange(output_rows, source_resource_id, source_row_number)[c11_columns],
                 dplyr::arrange(expected_source_rows, source_resource_id, source_row_number)[c11_columns]) ||
      !identical(sort(unique(output_rows$season_week_index)), seq_len(nrow(expected)))) {
    abort_season_scope("Season row-preservation or index reconciliation failed.")
  }

  resource_ids <- sort(unique(output_rows$source_resource_id))
  snapshot <- tibble::tibble(
    season_scope_snapshot_schema_version = "1.0.0",
    season_scope_id = season_config$scope_id,
    season_label = season_config$season_label,
    expected_season_week_count = nrow(expected),
    observed_season_week_count = nrow(observed),
    missing_season_week_count = nrow(missing),
    unexpected_season_week_count = nrow(unexpected),
    season_week_coverage_status = coverage_status,
    source_schema_family = families[[1]],
    source_resource_count = length(resource_ids),
    source_resource_ids = paste(resource_ids, collapse = "|"),
    season_row_count = nrow(output_rows),
    season_published_case_count = sum(output_rows$source_case_count)
  )[, snapshot_columns]
  if (nrow(snapshot) != 1L || !identical(names(snapshot), snapshot_columns)) {
    abort_season_scope("Season snapshot schema validation failed.")
  }

  publish_csv(output_rows, output_path, ".season_scope_")
  publish_csv(snapshot, snapshot_path, ".season_scope_snapshot_")
  invisible(list(rows = output_rows, snapshot = snapshot))
}

if (sys.nframe() == 0L) main()
