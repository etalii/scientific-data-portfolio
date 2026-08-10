# Download-log contract interface. Loading this file has no side effects.

download_log_contract_version <- "1.0.0"
download_log_columns <- c("log_schema_version", "event_type", "run_id", "event_at_utc", "catalog_contract_version", "resource_id", "download_url", "local_filename", "destination_path", "outcome", "attempt_count", "http_status", "file_size_bytes", "sha256", "error_class", "error_message")
download_log_event_types <- c("run_started", "run_failed_preflight", "resource_result", "run_finished")
download_log_outcomes <- c("started", "failed_preflight", "downloaded", "skipped_existing_verified", "failed_download", "failed_integrity", "conflict_existing_file", "completed", "completed_with_failures")
download_log_error_classes <- c("connection_or_timeout", "tls_certificate_validation", "http_error", "empty_download", "existing_file", "publication_copy", "publication_verification", "publication_rename", "unexpected_error", "preflight")

abort_download_log <- function(message) stop(message, call. = FALSE)
read_download_log <- function(path) tryCatch(readr::read_csv(path, show_col_types = FALSE, na = character(), col_types = readr::cols(.default = readr::col_character())), error = function(error) abort_download_log(sprintf("Existing download log is not valid CSV: %s", error$message)))
present_log_value <- function(x) !is.na(x) & nzchar(x)
empty_log_value <- function(x) is.na(x) | !nzchar(x)
non_negative_integer <- function(x) grepl("^[0-9]+$", x) & suppressWarnings(as.numeric(x)) <= .Machine$integer.max
positive_integer <- function(x) non_negative_integer(x) & suppressWarnings(as.numeric(x)) > 0
relative_log_path <- function(x) present_log_value(x) & !grepl("^(/|[[:alpha:]]:[/\\\\])", x) & !grepl("(^|/)\\.\\.(/|$)", x)

validate_download_log_semantics <- function(x) {
  required <- c("log_schema_version", "event_type", "run_id", "event_at_utc", "catalog_contract_version", "outcome")
  invalid <- any(vapply(required, function(n) any(!present_log_value(x[[n]])), logical(1))) || any(!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", x$event_at_utc)) || any(!x$error_class %in% c("", download_log_error_classes))
  run <- x$event_type %in% c("run_started", "run_failed_preflight", "run_finished"); fields <- c("resource_id", "download_url", "local_filename", "destination_path", "attempt_count", "http_status", "file_size_bytes", "sha256")
  invalid <- invalid || any(vapply(fields, function(n) any(run & !empty_log_value(x[[n]])), logical(1))) || any(x$event_type == "run_started" & x$outcome != "started") || any(x$event_type == "run_failed_preflight" & x$outcome != "failed_preflight") || any(x$event_type == "run_finished" & !x$outcome %in% c("completed", "completed_with_failures"))
  resource <- x$event_type == "resource_result"; required_resource <- c("resource_id", "download_url", "local_filename", "destination_path", "attempt_count")
  invalid <- invalid || any(vapply(required_resource, function(n) any(resource & !present_log_value(x[[n]])), logical(1))) || any(resource & !grepl("^https?://", x$download_url)) || any(resource & !relative_log_path(x$destination_path)) || any(resource & !non_negative_integer(x$attempt_count))
  success <- resource & x$outcome %in% c("downloaded", "skipped_existing_verified")
  invalid <- invalid || any(success & (!positive_integer(x$file_size_bytes) | !grepl("^[a-f0-9]{64}$", x$sha256))) || any(resource & x$outcome == "downloaded" & (!positive_integer(x$attempt_count) | !grepl("^2[0-9]{2}$", x$http_status))) || any(resource & x$outcome == "skipped_existing_verified" & (x$attempt_count != "0" | !empty_log_value(x$http_status)))
  failed <- resource & !x$outcome %in% c("downloaded", "skipped_existing_verified")
  invalid <- invalid || any(failed & (!present_log_value(x$error_class) | !present_log_value(x$error_message)))
  if (invalid) abort_download_log("Existing download log does not satisfy download_log contract 1.0.0.")
  invisible(TRUE)
}
validate_existing_download_log <- function(path) {
  if (!file.exists(path)) return(invisible(TRUE))
  x <- read_download_log(path)
  if (!identical(names(x), download_log_columns) || nrow(readr::problems(x)) > 0L || any(x$log_schema_version != download_log_contract_version) || any(!x$event_type %in% download_log_event_types) || any(!x$outcome %in% download_log_outcomes)) abort_download_log("Existing download log does not satisfy download_log contract 1.0.0.")
  validate_download_log_semantics(x)
}
