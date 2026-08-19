###############################################################
# Argentina Dengue Analysis
# Script: 03_select_canonical_resources.R
# Purpose: Select one canonical resource per exact temporal-coverage group.
# Inputs: project configuration, resource catalog, validation snapshot, raw CSVs.
# Output: data/metadata/canonical_resources.csv.
###############################################################

canonical_selection_version <- "1.0.0"
canonical_selection_columns <- c(
  "canonical_selection_schema_version", "resource_id", "local_filename",
  "coverage_start_year", "coverage_start_week", "coverage_end_year",
  "coverage_end_week", "coverage_week_count", "coverage_signature",
  "source_last_modified_at", "competition_count", "selection_status",
  "selection_reason", "superseded_by_resource_id", "processing_authorized"
)

#' Abort canonical resource selection with a clear contract error.
#'
#' @param message Message displayed to the user.
#' @return This function does not return.
abort_selection <- function(message) {
  stop(message, call. = FALSE)
}

#' Read the centrally configured project settings.
#'
#' @return Parsed project configuration.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) {
    abort_selection("Configuration file not found: config/project.yml")
  }

  tryCatch(
    yaml::read_yaml("config/project.yml"),
    error = function(error) abort_selection(sprintf("Could not read configuration: %s", error$message))
  )
}

#' Extract a required non-empty scalar string from configuration.
#'
#' @param config Parsed configuration.
#' @param section First-level configuration section.
#' @param key Configuration key.
#' @return Trimmed string value.
required_string <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (is.null(value) || length(value) != 1L || !is.character(value) || is.na(value) || !nzchar(trimws(value))) {
    abort_selection(sprintf("Missing or invalid configuration value: %s.%s", section, key))
  }
  trimws(value)
}

#' Ensure a configured path is relative to the project root.
#'
#' @param path Configured path.
#' @param label Human-readable configuration label.
#' @return Invisibly returns path.
require_relative_path <- function(path, label) {
  if (grepl("^(/|[[:alpha:]]:[/\\\\])", path)) {
    abort_selection(sprintf("%s must be relative to the project root: %s", label, path))
  }
  invisible(path)
}

#' Determine whether a configured path belongs to a configured directory.
#'
#' @param path Project-relative path.
#' @param directory Project-relative directory.
#' @return Whether path is inside directory.
inside_directory <- function(path, directory) {
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidate <- normalizePath(file.path(root, path), winslash = "/", mustWork = FALSE)
  parent <- normalizePath(file.path(root, directory), winslash = "/", mustWork = FALSE)
  startsWith(candidate, paste0(parent, "/"))
}

#' Validate the configuration required by canonical selection.
#'
#' @param config Parsed configuration.
#' @return Named list of validated settings.
selection_config <- function(config) {
  paths <- list(
    raw_directory = required_string(config, "directories", "raw_data"),
    metadata_directory = required_string(config, "directories", "metadata"),
    catalog_path = required_string(config, "artifacts", "resources_catalog"),
    snapshot_path = required_string(config, "artifacts", "validation_snapshot"),
    manifest_path = required_string(config, "artifacts", "canonical_resources")
  )
  purrr::iwalk(paths, require_relative_path)
  if (!all(vapply(paths[c("catalog_path", "snapshot_path", "manifest_path")], inside_directory, logical(1), directory = paths$metadata_directory))) {
    abort_selection("Canonical-selection artifacts must belong to the configured metadata directory.")
  }

  encodings <- config$canonicalization$header_encodings
  if (!is.character(encodings) || length(encodings) < 1L || !identical(encodings[[1]], "UTF-8") || any(!nzchar(encodings))) {
    abort_selection("canonicalization.header_encodings must start with UTF-8 and contain non-empty encodings.")
  }
  pairs <- config$canonicalization$temporal_column_pairs
  valid_pair <- function(pair) is.list(pair) && all(c("year_column", "week_column") %in% names(pair)) && all(vapply(pair[c("year_column", "week_column")], function(value) is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value), logical(1)))
  if (!is.list(pairs) || !length(pairs) || !all(vapply(pairs, valid_pair, logical(1)))) {
    abort_selection("canonicalization.temporal_column_pairs must contain valid year/week pairs.")
  }
  pair_keys <- vapply(pairs, function(pair) paste(pair$year_column, pair$week_column, sep = "\r"), character(1))
  if (anyDuplicated(pair_keys)) abort_selection("Configured temporal column pairs must be unique.")

  c(paths, list(header_encodings = encodings, temporal_pairs = pairs))
}

#' Read and validate the resources catalog contract.
#'
#' @param path Catalog path.
#' @return Typed catalog tibble.
read_resources_catalog <- function(path) {
  columns <- c("resource_id", "resource_name", "resource_description", "resource_format", "download_url", "local_filename", "source_created_at", "source_last_modified_at", "source_resource_state", "eligible_for_download", "eligibility_reason")
  catalog <- readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character(), eligible_for_download = readr::col_logical()))
  if (!identical(names(catalog), columns) || nrow(readr::problems(catalog)) || anyDuplicated(catalog$resource_id) || any(!nzchar(catalog$resource_id)) || any(!nzchar(catalog$local_filename))) {
    abort_selection("Resources catalog does not satisfy resources_catalog contract 2.0.0.")
  }
  catalog
}

#' Read and validate the validation snapshot needed for canonical selection.
#'
#' @param path Validation snapshot path.
#' @return Typed in-scope snapshot tibble.
read_validation_snapshot <- function(path) {
  columns <- c("validation_schema_version", "validation_run_id", "validated_at_utc", "record_type", "record_key", "resource_id", "eligible_for_download", "download_url", "local_filename", "destination_path", "provenance_event_type", "provenance_run_id", "provenance_event_at_utc", "provenance_evidence_count", "expected_file_size_bytes", "expected_sha256", "observed_file_size_bytes", "observed_sha256", "physical_status", "provenance_status", "readability_status", "csv_delimiter", "csv_column_count", "validation_outcome", "diagnostic_code", "processing_eligible")
  snapshot <- readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character(), eligible_for_download = readr::col_logical(), processing_eligible = readr::col_logical(), csv_column_count = readr::col_integer()))
  if (!identical(names(snapshot), columns) || nrow(readr::problems(snapshot)) || any(snapshot$validation_schema_version != "1.0.0")) {
    abort_selection("Validation snapshot does not satisfy validation_snapshot contract 1.0.0.")
  }
  in_scope <- dplyr::filter(snapshot, .data$record_type == "catalog_resource", .data$processing_eligible %in% TRUE)
  if (anyDuplicated(in_scope$resource_id) || any(!in_scope$eligible_for_download) || any(in_scope$validation_outcome != "valid") || any(in_scope$physical_status != "passed") || any(in_scope$provenance_status != "passed") || any(in_scope$readability_status != "passed")) {
    abort_selection("Processing-eligible validation rows violate the validation snapshot handoff policy.")
  }
  in_scope
}

#' Read raw bytes through the first line ending of a file.
#'
#' @param path CSV path.
#' @return Raw header bytes without the line ending.
read_header_bytes <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  bytes <- readBin(connection, what = "raw", n = 65536L)
  newline <- which(as.integer(bytes) == 10L)
  if (!length(newline)) abort_selection(sprintf("CSV header is missing or exceeds the supported preflight size: %s", path))
  header <- bytes[seq_len(newline[[1]] - 1L)]
  if (length(header) && as.integer(header[[length(header)]]) == 13L) header <- header[-length(header)]
  header
}

#' Decode a CSV header according to the contractual ordered encoding policy.
#'
#' @param path CSV path.
#' @param encodings Ordered configured encodings, beginning with UTF-8.
#' @return List containing decoded header text and selected encoding.
decode_header <- function(path, encodings) {
  raw_header <- rawToChar(read_header_bytes(path))
  utf8_header <- iconv(raw_header, from = "UTF-8", to = "UTF-8", sub = NA_character_)
  candidates <- if (!is.na(utf8_header)) "UTF-8" else encodings[-1L]
  if (!length(candidates)) abort_selection(sprintf("Header is not valid UTF-8 and no fallback encoding is configured: %s", path))
  for (encoding in candidates) {
    decoded <- iconv(raw_header, from = encoding, to = "UTF-8", sub = NA_character_)
    if (!is.na(decoded)) return(list(text = sub("^\\ufeff", "", decoded), encoding = encoding))
  }
  abort_selection(sprintf("Header could not be decoded with configured encodings: %s", path))
}

#' Map the validation snapshot delimiter label to its literal delimiter.
#'
#' @param delimiter Contractual snapshot delimiter label.
#' @return Delimiter character.
delimiter_character <- function(delimiter) {
  value <- c(comma = ",", semicolon = ";", tab = "\t")[[delimiter]]
  if (is.null(value)) abort_selection(sprintf("Unsupported validation-snapshot delimiter: %s", delimiter))
  value
}

#' Read header names using the encoding selected from raw header bytes.
#'
#' @param path CSV path.
#' @param delimiter Literal delimiter.
#' @param encoding Selected header encoding.
#' @return Character vector of parsed header names.
read_header_names <- function(path, delimiter, encoding) {
  header <- tryCatch(
    readr::read_delim(path, delim = delimiter, n_max = 0L, show_col_types = FALSE, name_repair = "minimal", locale = readr::locale(encoding = encoding)),
    error = function(error) abort_selection(sprintf("Could not parse CSV header %s: %s", path, error$message))
  )
  names(header)
}

#' Recognize exactly one configured temporal pair after contractual decoding.
#'
#' @param header_names Parsed CSV header names.
#' @param pairs Configured temporal column-pair list.
#' @return The matching pair or NULL when recognition is ambiguous.
recognize_temporal_pair <- function(header_names, pairs) {
  matches <- vapply(pairs, function(pair) all(c(pair$year_column, pair$week_column) %in% header_names), logical(1))
  if (sum(matches) != 1L) return(NULL)
  pairs[[which(matches)[[1]]]]
}

#' Return NULL unless values are complete decimal integers in a valid range.
#'
#' @param values Character vector.
#' @param minimum Minimum inclusive value.
#' @param maximum Maximum inclusive value.
#' @return Integer vector or NULL.
parse_temporal_integers <- function(values, minimum, maximum) {
  values <- trimws(values)
  if (any(is.na(values)) || any(!grepl("^[0-9]+$", values))) return(NULL)
  parsed <- suppressWarnings(as.integer(values))
  if (any(is.na(parsed)) || any(parsed < minimum | parsed > maximum)) return(NULL)
  parsed
}

#' Calculate a lowercase SHA-256 from UTF-8 text.
#'
#' @param text Character scalar.
#' @return Lowercase hexadecimal SHA-256.
hash_utf8_text <- function(text) {
  bytes <- charToRaw(enc2utf8(text))
  paste(sprintf("%02x", as.integer(unclass(openssl::sha256(bytes)))), collapse = "")
}

#' Build unresolved canonical-selection fields for ambiguous coverage.
#'
#' @param resource Catalog resource row.
#' @return One-row canonical-selection tibble.
pending_coverage_row <- function(resource) {
  tibble::tibble(
    canonical_selection_schema_version = canonical_selection_version,
    resource_id = resource$resource_id,
    local_filename = resource$local_filename,
    coverage_start_year = NA_integer_, coverage_start_week = NA_integer_,
    coverage_end_year = NA_integer_, coverage_end_week = NA_integer_,
    coverage_week_count = NA_integer_, coverage_signature = NA_character_,
    source_last_modified_at = resource$source_last_modified_at,
    competition_count = NA_integer_, selection_status = "pending",
    selection_reason = "pending_ambiguous_coverage",
    superseded_by_resource_id = NA_character_, processing_authorized = FALSE
  )
}

#' Calculate exact temporal coverage for one validation-authorized resource.
#'
#' @param resource Catalog resource row.
#' @param snapshot_row Matching validation snapshot row.
#' @param raw_directory Configured raw directory.
#' @param config Validated canonical-selection configuration.
#' @return List with manifest row and preflight diagnostics.
calculate_coverage <- function(resource, snapshot_row, raw_directory, config) {
  path <- file.path(raw_directory, resource$local_filename)
  decoded <- decode_header(path, config$header_encodings)
  headers <- read_header_names(path, delimiter_character(snapshot_row$csv_delimiter), decoded$encoding)
  pair <- recognize_temporal_pair(headers, config$temporal_pairs)
  if (is.null(pair)) return(list(row = pending_coverage_row(resource), encoding = decoded$encoding, pair = NA_character_, coverage = NA_character_))

  temporal_data <- tryCatch(
    readr::read_delim(path, delim = delimiter_character(snapshot_row$csv_delimiter), col_select = dplyr::all_of(c(pair$year_column, pair$week_column)), col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE, name_repair = "minimal", locale = readr::locale(encoding = decoded$encoding)),
    error = function(error) NULL
  )
  if (is.null(temporal_data) || nrow(temporal_data) == 0L || nrow(readr::problems(temporal_data))) return(list(row = pending_coverage_row(resource), encoding = decoded$encoding, pair = paste(pair$year_column, pair$week_column, sep = " + "), coverage = NA_character_))
  years <- parse_temporal_integers(temporal_data[[pair$year_column]], 1000L, 9999L)
  weeks <- parse_temporal_integers(temporal_data[[pair$week_column]], 1L, 53L)
  if (is.null(years) || is.null(weeks)) return(list(row = pending_coverage_row(resource), encoding = decoded$encoding, pair = paste(pair$year_column, pair$week_column, sep = " + "), coverage = NA_character_))

  coverage <- dplyr::arrange(dplyr::distinct(tibble::tibble(year = years, week = weeks)), .data$year, .data$week)
  serialized <- paste(sprintf("%04d-%02d", coverage$year, coverage$week), collapse = "|")
  row <- tibble::tibble(
    canonical_selection_schema_version = canonical_selection_version,
    resource_id = resource$resource_id,
    local_filename = resource$local_filename,
    coverage_start_year = coverage$year[[1]], coverage_start_week = coverage$week[[1]],
    coverage_end_year = coverage$year[[nrow(coverage)]], coverage_end_week = coverage$week[[nrow(coverage)]],
    coverage_week_count = nrow(coverage), coverage_signature = hash_utf8_text(serialized),
    source_last_modified_at = resource$source_last_modified_at,
    competition_count = NA_integer_, selection_status = NA_character_,
    selection_reason = NA_character_, superseded_by_resource_id = NA_character_,
    processing_authorized = FALSE
  )
  list(row = row, encoding = decoded$encoding, pair = paste(pair$year_column, pair$week_column, sep = " + "), coverage = serialized)
}

#' Apply canonical resource selection to determined coverage groups.
#'
#' @param rows Coverage rows before selection.
#' @return Canonical-selection rows with decisions.
select_canonical_resources <- function(rows) {
  known <- which(!is.na(rows$coverage_signature))
  for (indices in split(known, rows$coverage_signature[known])) {
    count <- length(indices)
    rows$competition_count[indices] <- count
    if (count == 1L) {
      rows$selection_status[indices] <- "included"
      rows$selection_reason[indices] <- "sole_available_resource"
      rows$processing_authorized[indices] <- TRUE
      next
    }
    timestamps <- rows$source_last_modified_at[indices]
    if (any(is.na(timestamps) | !nzchar(timestamps))) {
      rows$selection_status[indices] <- "pending"
      rows$selection_reason[indices] <- "pending_missing_source_timestamp"
      next
    }
    latest <- max(timestamps)
    winner <- indices[timestamps == latest]
    if (length(winner) != 1L) {
      rows$selection_status[indices] <- "pending"
      rows$selection_reason[indices] <- "pending_tied_source_timestamp"
      next
    }
    rows$selection_status[winner] <- "included"
    rows$selection_reason[winner] <- "selected_latest_source_revision"
    rows$processing_authorized[winner] <- TRUE
    losers <- setdiff(indices, winner)
    rows$selection_status[losers] <- "excluded"
    rows$selection_reason[losers] <- "superseded_by_latest_source_revision"
    rows$superseded_by_resource_id[losers] <- rows$resource_id[winner]
  }
  rows
}

#' Atomically publish the canonical manifest in its configured metadata directory.
#'
#' @param rows Completed manifest rows.
#' @param path Configured output path.
#' @return Invisibly TRUE on success.
publish_manifest <- function(rows, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(".argentina_dengue_canonical_", dirname(path), ".csv")
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(rows[, canonical_selection_columns], temporary, na = "")
  if (!file.rename(temporary, path)) abort_selection("Could not atomically publish canonical resources manifest.")
  invisible(TRUE)
}

#' Run canonical resource selection from the project root.
#'
#' @return Invisibly TRUE on success.
main <- function() {
  config <- selection_config(read_project_config())
  catalog <- read_resources_catalog(config$catalog_path)
  snapshot <- read_validation_snapshot(config$snapshot_path)
  resources <- dplyr::inner_join(snapshot[, c("resource_id", "local_filename", "csv_delimiter")], catalog, by = c("resource_id", "local_filename"))
  if (nrow(resources) != nrow(snapshot)) abort_selection("Validation snapshot resources do not match the current catalog identity.")

  results <- purrr::map(seq_len(nrow(resources)), function(index) calculate_coverage(resources[index, ], snapshot[index, ], config$raw_directory, config))
  purrr::walk(results, function(result) message(sprintf("%s | encoding=%s | temporal_pair=%s | coverage=%s", result$row$resource_id, result$encoding, result$pair, result$coverage)))
  rows <- dplyr::bind_rows(purrr::map(results, "row"))
  rows <- dplyr::arrange(select_canonical_resources(rows), .data$resource_id)
  publish_manifest(rows, config$manifest_path)
  invisible(TRUE)
}

if (length(commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]) == 1L && basename(sub("^--file=", "", commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")])) == "03_select_canonical_resources.R") {
  main()
}
