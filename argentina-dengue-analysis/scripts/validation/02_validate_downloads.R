###############################################################
# Argentina Dengue Analysis
# Script: 02_validate_downloads.R
# Purpose: Validate local raw files against internal provenance contracts.
###############################################################

snapshot_version <- "1.0.0"
snapshot_columns <- c("validation_schema_version", "validation_run_id", "validated_at_utc", "record_type", "record_key", "resource_id", "eligible_for_download", "download_url", "local_filename", "destination_path", "provenance_event_type", "provenance_run_id", "provenance_event_at_utc", "provenance_evidence_count", "expected_file_size_bytes", "expected_sha256", "observed_file_size_bytes", "observed_sha256", "physical_status", "provenance_status", "readability_status", "csv_delimiter", "csv_column_count", "validation_outcome", "diagnostic_code", "processing_eligible")

abort_validation <- function(message) stop(message, call. = FALSE)
utc_now <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
run_id <- function() sprintf("%s-%s", format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"), Sys.getpid())
hash_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste(sprintf("%02x", as.integer(unclass(openssl::sha256(connection)))), collapse = "")
}

read_config <- function() yaml::read_yaml("config/project.yml")
required <- function(x, section, key) {
  value <- x[[section]][[key]]
  if (is.null(value) || length(value) != 1L || !is.character(value) || !nzchar(value)) abort_validation(sprintf("Missing configuration: %s.%s", section, key))
  value
}
inside <- function(path, directory) startsWith(normalizePath(file.path(getwd(), path), mustWork = FALSE), paste0(normalizePath(file.path(getwd(), directory), mustWork = FALSE), "/"))

acquire_lock <- function(path, id) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (!dir.create(path, showWarnings = FALSE)) abort_validation(sprintf("Acquisition-validation lock already exists: %s", path))
  writeLines(c(paste0("run_id=", id), paste0("acquired_at_utc=", utc_now()), paste0("pid=", Sys.getpid())), file.path(path, "run_diagnostics.txt"))
}
release_lock <- function(path) if (dir.exists(path)) unlink(path, recursive = TRUE, force = FALSE)

read_catalog <- function(path) {
  expected <- c("resource_id", "resource_name", "resource_description", "resource_format", "download_url", "local_filename", "source_created_at", "source_last_modified_at", "source_resource_state", "eligible_for_download", "eligibility_reason")
  x <- readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character(), eligible_for_download = readr::col_logical()))
  if (!identical(names(x), expected) || nrow(readr::problems(x)) > 0L || anyDuplicated(x$resource_id)) abort_validation("Resources catalog does not satisfy resources_catalog contract 2.0.0.")
  x
}
read_log <- function(path) {
  source("scripts/utils/download_log.R", local = FALSE)
  validate_existing_download_log(path)
  read_download_log(path)
}
new_row <- function(id, time, type, key) {
  x <- as.list(rep("", length(snapshot_columns))); names(x) <- snapshot_columns
  x$validation_schema_version <- snapshot_version; x$validation_run_id <- id; x$validated_at_utc <- time; x$record_type <- type; x$record_key <- key
  x$physical_status <- "not_applicable"; x$provenance_status <- "not_applicable"; x$readability_status <- "not_applicable"; x$validation_outcome <- "not_applicable"; x$diagnostic_code <- "none"; x$processing_eligible <- FALSE
  tibble::as_tibble(x)
}
csv_check <- function(path) {
  candidates <- c(comma = ",", semicolon = ";", tab = "\t")
  parsed <- lapply(candidates, function(delimiter) tryCatch(readr::read_delim(path, delim = delimiter, n_max = 2L, show_col_types = FALSE, name_repair = "minimal", col_types = readr::cols(.default = readr::col_character())), error = function(error) error))
  valid <- vapply(parsed, function(result) !inherits(result, "error") && ncol(result) >= 2L && all(nzchar(names(result))) && nrow(readr::problems(result)) == 0L, logical(1))
  if (sum(valid) != 1L) return(list(status = "failed", delimiter = "", columns = "", code = "csv_delimiter_undetermined"))
  name <- names(candidates)[valid][[1]]; result <- parsed[[which(valid)[[1]]]]
  if (nrow(result) == 0L) return(list(status = "warning", delimiter = name, columns = as.character(ncol(result)), code = "csv_no_data_rows"))
  list(status = "passed", delimiter = name, columns = as.character(ncol(result)), code = "none")
}

validate_resource <- function(resource, log, raw_directory, id, time) {
  row <- new_row(id, time, "catalog_resource", resource$resource_id)
  row$resource_id <- resource$resource_id; row$eligible_for_download <- resource$eligible_for_download; row$download_url <- resource$download_url; row$local_filename <- resource$local_filename; row$destination_path <- file.path(raw_directory, resource$local_filename)
  destination <- file.path(getwd(), row$destination_path)
  successes <- dplyr::filter(log, .data$event_type == "resource_result", .data$outcome %in% c("downloaded", "skipped_existing_verified"), .data$resource_id == resource$resource_id, .data$download_url == resource$download_url, .data$local_filename == resource$local_filename, .data$destination_path == row$destination_path)
  payloads <- dplyr::distinct(successes, .data$file_size_bytes, .data$sha256)
  if (!resource$eligible_for_download) { row$diagnostic_code <- "not_currently_eligible"; return(row) }
  if (nrow(payloads) == 0L) { row$provenance_status <- "failed"; row$validation_outcome <- "invalid"; row$diagnostic_code <- "provenance_missing"; return(row) }
  if (nrow(payloads) > 1L) { row$provenance_status <- "failed"; row$validation_outcome <- "invalid"; row$diagnostic_code <- "provenance_conflict"; return(row) }
  evidence <- successes[nrow(successes), ]; row$provenance_status <- "passed"; row$provenance_event_type <- evidence$outcome; row$provenance_run_id <- evidence$run_id; row$provenance_event_at_utc <- evidence$event_at_utc; row$provenance_evidence_count <- as.character(nrow(successes)); row$expected_file_size_bytes <- evidence$file_size_bytes; row$expected_sha256 <- evidence$sha256
  if (!file.exists(destination)) { row$physical_status <- "failed"; row$validation_outcome <- "invalid"; row$diagnostic_code <- "missing_file"; return(row) }
  if (!isTRUE(file.info(destination)$isdir) && file.info(destination)$size > 0) { row$observed_file_size_bytes <- as.character(file.info(destination)$size); row$observed_sha256 <- hash_file(destination) } else { row$physical_status <- "failed"; row$validation_outcome <- "invalid"; row$diagnostic_code <- if (isTRUE(file.info(destination)$isdir)) "not_regular_file" else "empty_file"; return(row) }
  if (row$observed_file_size_bytes != row$expected_file_size_bytes) { row$physical_status <- "failed"; row$validation_outcome <- "invalid"; row$diagnostic_code <- "size_mismatch"; return(row) }
  if (row$observed_sha256 != row$expected_sha256) { row$physical_status <- "failed"; row$validation_outcome <- "invalid"; row$diagnostic_code <- "sha256_mismatch"; return(row) }
  row$physical_status <- "passed"; readable <- csv_check(destination); row$readability_status <- readable$status; row$csv_delimiter <- readable$delimiter; row$csv_column_count <- readable$columns; row$diagnostic_code <- readable$code
  row$validation_outcome <- if (readable$status == "passed") "valid" else if (readable$status == "warning") "valid_with_warning" else "invalid"; row$processing_eligible <- identical(row$validation_outcome, "valid"); row
}

main <- function() {
  config <- read_config(); raw <- required(config, "directories", "raw_data"); metadata <- required(config, "directories", "metadata"); catalog_path <- required(config, "artifacts", "resources_catalog"); log_path <- required(config, "logs", "download"); lock <- required(config, "artifacts", "acquisition_validation_lock"); snapshot <- required(config, "artifacts", "validation_snapshot")
  if (!inside(catalog_path, metadata) || !inside(log_path, metadata) || !inside(lock, metadata) || !inside(snapshot, metadata)) abort_validation("Validation artifacts and lock must belong to the metadata directory.")
  id <- run_id(); acquire_lock(lock, id); on.exit(release_lock(lock), add = TRUE); if (!dir.exists(raw)) abort_validation("Raw-data directory does not exist.")
  if (length(list.files(raw, pattern = "^\\.argentina_dengue_publish--.*\\.part$", all.files = TRUE))) abort_validation("Residual publication temporary detected in raw data.")
  catalog <- read_catalog(catalog_path); log <- read_log(log_path); time <- utc_now(); rows <- purrr::map_dfr(seq_len(nrow(catalog)), ~validate_resource(catalog[.x, ], log, raw, id, time))
  expected <- catalog$local_filename; observed <- setdiff(list.files(raw, all.files = TRUE, no.. = TRUE), c(".gitkeep", expected)); if (length(observed)) rows <- dplyr::bind_rows(rows, purrr::map_dfr(observed, function(name) { x <- new_row(id, time, "raw_file_unattributed", name); x$local_filename <- name; x$destination_path <- file.path(raw, name); x$validation_outcome <- "invalid"; x$provenance_status <- "failed"; x$diagnostic_code <- "raw_file_unattributed"; x }))
  rows <- dplyr::arrange(rows, .data$record_type, .data$record_key); dir.create(dirname(snapshot), recursive = TRUE, showWarnings = FALSE); tmp <- tempfile(".argentina_dengue_validation_", dirname(snapshot), ".csv"); on.exit(unlink(tmp), add = TRUE); readr::write_csv(rows, tmp, na = ""); if (!file.rename(tmp, snapshot)) abort_validation("Could not publish validation snapshot.")
  invisible(TRUE)
}

if (length(commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]) == 1L && basename(sub("^--file=", "", commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")])) == "02_validate_downloads.R") main()
