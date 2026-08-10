###############################################################
# Argentina Dengue Analysis
#
# Script:
#   01_download_data.R
#
# Purpose:
#   Download technically eligible resources from the internal catalog,
#   publish verified immutable raw files, and record operational events.
#
# Inputs:
#   config/project.yml
#   data/metadata/resources_catalog.csv
#   data/metadata/download_log.csv, when it already exists
#
# Outputs:
#   Verified files in data/raw/
#   data/metadata/download_log.csv
###############################################################

resources_catalog_contract_version <- "2.0.0"

# Load the shared download-log contract interface without executing a pipeline.
source("scripts/utils/download_log.R", local = FALSE)

#' Stop execution with a project-specific error message.
#'
#' @param message Error message to display.
#' @return This function does not return.
abort_download <- function(message) {
  stop(message, call. = FALSE)
}

#' Read the project configuration file.
#'
#' @param config_path Path to config/project.yml.
#' @return Parsed project configuration.
read_project_config <- function(config_path) {
  if (!file.exists(config_path)) {
    abort_download(sprintf("Configuration file not found: %s", config_path))
  }

  tryCatch(
    yaml::read_yaml(config_path),
    error = function(error) {
      abort_download(sprintf("Could not read project configuration: %s", error$message))
    }
  )
}

#' Get a required non-empty scalar character configuration value.
#'
#' @param config Parsed project configuration.
#' @param section First-level configuration section.
#' @param key Required key within section.
#' @return Trimmed scalar character value.
get_required_config_string <- function(config, section, key) {
  value <- config[[section]][[key]]

  if (
    is.null(value) || length(value) != 1L || !is.character(value) ||
      is.na(value) || !nzchar(trimws(value))
  ) {
    abort_download(sprintf("Missing or invalid configuration value: %s.%s", section, key))
  }

  trimws(value)
}

#' Get a required non-negative numeric configuration value.
#'
#' @param config Parsed project configuration.
#' @param section First-level configuration section.
#' @param key Required key within section.
#' @param integer_only Whether the value must be an integer.
#' @return Numeric configuration value.
get_required_config_number <- function(config, section, key, integer_only = FALSE) {
  value <- config[[section]][[key]]

  if (
    is.null(value) || length(value) != 1L || !is.numeric(value) ||
      is.na(value) || value < 0 || (integer_only && value != as.integer(value))
  ) {
    abort_download(sprintf("Missing or invalid configuration value: %s.%s", section, key))
  }

  value
}

#' Reject absolute paths because project artifacts must be project-relative.
#'
#' @param path Configured artifact or directory path.
#' @param label Human-readable path label.
#' @return Invisibly returns path when it is relative.
validate_relative_path <- function(path, label) {
  if (grepl("^(/|[[:alpha:]]:[/\\\\])", path)) {
    abort_download(sprintf("%s must be relative to the project root: %s", label, path))
  }

  invisible(path)
}

#' Normalize a project-relative path without requiring it to exist.
#'
#' @param path Project-relative path.
#' @return Absolute normalized path.
normalize_project_path <- function(path) {
  normalizePath(file.path(getwd(), path), winslash = "/", mustWork = FALSE)
}

#' Determine whether one normalized path belongs to another directory.
#'
#' @param path Path to check.
#' @param directory Containing directory.
#' @return TRUE when path is inside directory.
is_path_inside_directory <- function(path, directory) {
  normalized_path <- normalize_project_path(path)
  normalized_directory <- normalize_project_path(directory)

  startsWith(normalized_path, paste0(normalized_directory, "/"))
}

#' Validate the configuration required by the download contract.
#'
#' @param config Parsed project configuration.
#' @return Download-specific configuration values.
validate_download_config <- function(config) {
  download_config <- list(
    raw_directory = get_required_config_string(config, "directories", "raw_data"),
    metadata_directory = get_required_config_string(config, "directories", "metadata"),
    staging_directory = get_required_config_string(config, "directories", "download_staging"),
    catalog_path = get_required_config_string(config, "artifacts", "resources_catalog"),
    lock_path = get_required_config_string(config, "artifacts", "acquisition_validation_lock"),
    log_path = get_required_config_string(config, "logs", "download"),
    timeout_seconds = get_required_config_number(config, "download", "timeout_seconds"),
    max_retries = get_required_config_number(
      config,
      "download",
      "max_retries",
      integer_only = TRUE
    ),
    retry_backoff_seconds = get_required_config_number(
      config,
      "download",
      "retry_backoff_seconds"
    )
  )

  purrr::iwalk(download_config[c(
    "raw_directory", "metadata_directory", "staging_directory", "catalog_path", "lock_path", "log_path"
  )], validate_relative_path)

  if (!is_path_inside_directory(download_config$catalog_path, download_config$metadata_directory)) {
    abort_download("resources_catalog path must belong to the configured metadata directory.")
  }

  if (!is_path_inside_directory(download_config$log_path, download_config$metadata_directory)) {
    abort_download("download_log path must belong to the configured metadata directory.")
  }

  if (!is_path_inside_directory(download_config$lock_path, download_config$metadata_directory)) {
    abort_download("acquisition_validation_lock path must belong to the configured metadata directory.")
  }

  if (is_path_inside_directory(download_config$staging_directory, download_config$raw_directory)) {
    abort_download("download_staging must be outside the configured raw-data directory.")
  }

  download_config
}

#' Create a directory or fail with a clear message.
#'
#' @param path Directory path.
#' @param label Human-readable directory label.
#' @return Invisibly returns path.
ensure_directory <- function(path, label) {
  if (!dir.exists(path) && !dir.create(path, recursive = TRUE, showWarnings = FALSE)) {
    abort_download(sprintf("Could not create %s: %s", label, path))
  }

  invisible(path)
}

#' Create an opaque, filesystem-safe identifier for one download run.
#'
#' @return Run identifier string.
create_run_id <- function() {
  sprintf(
    "%s-%s-%s",
    format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC"),
    Sys.getpid(),
    sprintf("%06d", sample.int(999999L, 1L))
  )
}

#' Return the current timestamp in ISO 8601 UTC notation.
#'
#' @return Timestamp string.
current_utc_timestamp <- function() {
  format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

#' Write diagnostic information after an exclusive lock is acquired.
#'
#' @param lock_path Acquired lock directory.
#' @param run_id Current run identifier.
#' @return Invisibly returns the diagnostic file path.
write_lock_diagnostics <- function(lock_path, run_id) {
  diagnostic_path <- file.path(lock_path, "run_diagnostics.txt")
  diagnostic_lines <- c(
    sprintf("run_id=%s", run_id),
    sprintf("acquired_at_utc=%s", current_utc_timestamp()),
    sprintf("pid=%s", Sys.getpid()),
    sprintf("hostname=%s", Sys.info()[["nodename"]])
  )

  tryCatch(
    writeLines(diagnostic_lines, diagnostic_path),
    error = function(error) {
      abort_download(sprintf("Could not write lock diagnostics: %s", error$message))
    }
  )

  invisible(diagnostic_path)
}

#' Acquire the configured workspace-exclusive download lock atomically.
#'
#' @param lock_path Configured lock directory.
#' @param run_id Current run identifier.
#' @return Invisibly returns lock_path when acquired.
acquire_download_lock <- function(lock_path, run_id) {
  ensure_directory(dirname(lock_path), "metadata directory")

  if (!dir.create(lock_path, recursive = FALSE, showWarnings = FALSE)) {
    abort_download(
      sprintf(
        "Download lock already exists: %s. Inspect it before starting another run.",
        lock_path
      )
    )
  }

  tryCatch(
    write_lock_diagnostics(lock_path, run_id),
    error = function(error) {
      unlink(lock_path, recursive = TRUE, force = FALSE)
      stop(error)
    }
  )

  invisible(lock_path)
}

#' Release a lock directory after a controlled execution.
#'
#' @param lock_path Acquired lock directory.
#' @return Invisibly returns TRUE when the directory no longer exists.
release_download_lock <- function(lock_path) {
  if (dir.exists(lock_path) && unlink(lock_path, recursive = TRUE, force = FALSE) != 0L) {
    warning(sprintf("Could not release download lock: %s", lock_path), call. = FALSE)
    return(invisible(FALSE))
  }

  invisible(TRUE)
}

#' Identify only project-owned residual publication temporaries.
#'
#' @param raw_directory Raw-data directory.
#' @return Character vector of residual temporary filenames.
find_residual_publication_temporaries <- function(raw_directory) {
  temporary_pattern <- paste0(
    "^\\.argentina_dengue_publish--[[:alnum:]][[:alnum:]_.-]*--",
    "[[:alnum:]][[:alnum:]_.-]*\\.part$"
  )

  list.files(
    raw_directory,
    pattern = temporary_pattern,
    all.files = TRUE,
    no.. = TRUE,
    full.names = FALSE
  )
}

#' Read and validate the resources catalog contract.
#'
#' @param catalog_path Configured catalog path.
#' @return Catalog rows eligible for download.
read_eligible_catalog <- function(catalog_path) {
  expected_columns <- c(
    "resource_id",
    "resource_name",
    "resource_description",
    "resource_format",
    "download_url",
    "local_filename",
    "source_created_at",
    "source_last_modified_at",
    "source_resource_state",
    "eligible_for_download",
    "eligibility_reason"
  )

  if (!file.exists(catalog_path)) {
    abort_download(sprintf("Resources catalog not found: %s", catalog_path))
  }

  catalog <- tryCatch(
    readr::read_csv(
      catalog_path,
      show_col_types = FALSE,
      col_types = readr::cols(
        .default = readr::col_character(),
        eligible_for_download = readr::col_logical()
      )
    ),
    error = function(error) {
      abort_download(sprintf("Could not read resources catalog: %s", error$message))
    }
  )

  if (!identical(names(catalog), expected_columns) || nrow(readr::problems(catalog)) > 0L) {
    abort_download("Resources catalog does not match contract version 2.0.0.")
  }

  if (anyDuplicated(catalog$resource_id)) {
    abort_download("Resources catalog contains duplicate resource_id values.")
  }

  eligible_catalog <- dplyr::filter(catalog, .data$eligible_for_download)

  if (nrow(eligible_catalog) == 0L) {
    abort_download("Resources catalog contains no resources eligible for download.")
  }

  required_values <- c("resource_id", "download_url", "local_filename", "eligibility_reason")

  if (any(purrr::map_lgl(required_values, function(column) {
    any(is.na(eligible_catalog[[column]]) | !nzchar(eligible_catalog[[column]]))
  }))) {
    abort_download("An eligible catalog resource is missing a required value.")
  }

  if (
    any(!grepl("^https?://", eligible_catalog$download_url)) ||
      any(!grepl("^[[:alnum:]][[:alnum:]_.-]*$", eligible_catalog$local_filename)) ||
      anyDuplicated(eligible_catalog$local_filename)
  ) {
    abort_download("Eligible catalog resources contain invalid URLs or local filenames.")
  }

  eligible_catalog
}

#' Construct an empty event row matching the download-log contract.
#'
#' @param event_type Controlled event type.
#' @param run_id Current run identifier.
#' @param outcome Controlled outcome.
#' @return One-row tibble with nullable fields empty.
new_log_event <- function(event_type, run_id, outcome) {
  tibble::tibble(
    log_schema_version = download_log_contract_version,
    event_type = event_type,
    run_id = run_id,
    event_at_utc = current_utc_timestamp(),
    catalog_contract_version = resources_catalog_contract_version,
    resource_id = NA_character_,
    download_url = NA_character_,
    local_filename = NA_character_,
    destination_path = NA_character_,
    outcome = outcome,
    attempt_count = NA_integer_,
    http_status = NA_integer_,
    file_size_bytes = NA_real_,
    sha256 = NA_character_,
    error_class = NA_character_,
    error_message = NA_character_
  )
}

#' Remove credentials from a diagnostic message before logging it.
#'
#' @param message Error message.
#' @return Sanitized message.
sanitize_error_message <- function(message) {
  gsub("://[^/@[:space:]]+@", "://***@", message)
}



#' Read raw bytes from a file without changing its contents.
#'
#' @param path File path.
#' @return Raw vector containing file bytes.
read_file_bytes <- function(path) {
  file_size <- file.info(path)$size

  if (is.na(file_size)) {
    abort_download(sprintf("Could not determine file size: %s", path))
  }

  readBin(path, what = "raw", n = file_size)
}

#' Append one event with atomic physical publication and logical append semantics.
#'
#' @param event One-row log event tibble.
#' @param log_path Configured download-log path.
#' @return Invisibly returns log_path.
append_download_log_event <- function(event, log_path) {
  validate_existing_download_log(log_path)
  ensure_directory(dirname(log_path), "metadata directory")

  temporary_log_path <- tempfile(
    pattern = ".argentina_dengue_download_log_",
    tmpdir = dirname(log_path),
    fileext = ".csv"
  )
  event_row_path <- tempfile(
    pattern = ".argentina_dengue_download_event_",
    tmpdir = dirname(log_path),
    fileext = ".csv"
  )
  on.exit(unlink(c(temporary_log_path, event_row_path)), add = TRUE)

  if (file.exists(log_path)) {
    writeBin(read_file_bytes(log_path), temporary_log_path)

    existing_bytes <- read_file_bytes(temporary_log_path)

    if (length(existing_bytes) > 0L && tail(existing_bytes, 1L) != as.raw(10L)) {
      writeBin(as.raw(10L), temporary_log_path, useBytes = TRUE)
    }
  }

  tryCatch(
    readr::write_csv(
      event,
      event_row_path,
      na = "",
      append = FALSE,
      col_names = !file.exists(log_path)
    ),
    error = function(error) {
      abort_download(sprintf("Could not serialize download-log event: %s", error$message))
    }
  )

  temporary_connection <- file(temporary_log_path, open = "ab")
  writeBin(read_file_bytes(event_row_path), temporary_connection)
  close(temporary_connection)

  if (!file.rename(temporary_log_path, log_path)) {
    abort_download(sprintf("Could not publish download log: %s", log_path))
  }

  invisible(log_path)
}

#' Calculate a lowercase SHA-256 checksum for a file.
#'
#' @param path File path.
#' @return Lowercase hexadecimal SHA-256 string.
calculate_sha256 <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)

  checksum <- tryCatch(
    openssl::sha256(connection),
    error = function(error) {
      abort_download(sprintf("Could not calculate SHA-256 for '%s': %s", path, error$message))
    }
  )

  tolower(gsub(":", "", as.character(checksum)))
}

#' Build a project-relative destination path for a raw file.
#'
#' @param raw_directory Configured project-relative raw-data directory.
#' @param local_filename Catalog local filename.
#' @return Project-relative destination path.
build_destination_path <- function(raw_directory, local_filename) {
  file.path(raw_directory, local_filename)
}

#' Create a hidden temporary path for atomic raw-data publication.
#'
#' @param raw_directory Configured raw-data directory.
#' @param resource_id Catalog resource identifier.
#' @param run_id Current run identifier.
#' @return Publication temporary path.
build_publication_temporary_path <- function(raw_directory, resource_id, run_id) {
  file.path(
    raw_directory,
    sprintf(".argentina_dengue_publish--%s--%s.part", resource_id, run_id)
  )
}

#' Determine whether an HTTP status should be retried.
#'
#' @param status_code HTTP status code.
#' @return TRUE for transient retryable statuses.
is_retryable_http_status <- function(status_code) {
  identical(status_code, 429L) || status_code %in% c(500L, 502L, 503L, 504L)
}

#' Classify a request error and determine whether it can be retried.
#'
#' @param error Error returned by the HTTP client.
#' @return List with the stable error class and retry eligibility.
classify_request_error <- function(error) {
  error_message <- conditionMessage(error)
  tls_certificate_pattern <- paste(
    "SSL peer certificate",
    "SSL certificate problem",
    "certificate verify failed",
    "unable to get local issuer certificate",
    sep = "|"
  )

  if (grepl(tls_certificate_pattern, error_message, ignore.case = TRUE)) {
    return(list(
      error_class = "tls_certificate_validation",
      retryable = FALSE
    ))
  }

  list(error_class = "connection_or_timeout", retryable = TRUE)
}

#' Download one resource to external staging with transient-only retries.
#'
#' @param resource One-row catalog tibble.
#' @param config Download-specific configuration.
#' @param run_id Current run identifier.
#' @return Download result list.
download_to_staging <- function(resource, config, run_id) {
  staging_path <- file.path(
    config$staging_directory,
    sprintf(".argentina_dengue_stage--%s--%s.part", resource$resource_id, run_id)
  )
  max_attempts <- config$max_retries + 1L
  retain_staging_file <- FALSE
  on.exit(
    if (!retain_staging_file) {
      unlink(staging_path)
    },
    add = TRUE
  )

  for (attempt in seq_len(max_attempts)) {
    unlink(staging_path)

    response <- tryCatch(
      {
        request <- httr2::request(resource$download_url) |>
          httr2::req_timeout(config$timeout_seconds) |>
          httr2::req_error(is_error = function(response) FALSE)
        httr2::req_perform(request, path = staging_path)
      },
      error = function(error) error
    )

    if (inherits(response, "error")) {
      error_details <- classify_request_error(response)

      if (attempt < max_attempts && error_details$retryable) {
        Sys.sleep(config$retry_backoff_seconds * 2^(attempt - 1L))
        next
      }

      return(list(
        success = FALSE,
        attempt_count = attempt,
        http_status = NA_integer_,
        error_class = error_details$error_class,
        error_message = sanitize_error_message(conditionMessage(response))
      ))
    }

    status_code <- httr2::resp_status(response)

    if (status_code < 200L || status_code >= 300L) {
      unlink(staging_path)

      if (attempt < max_attempts && is_retryable_http_status(status_code)) {
        Sys.sleep(config$retry_backoff_seconds * 2^(attempt - 1L))
        next
      }

      return(list(
        success = FALSE,
        attempt_count = attempt,
        http_status = as.integer(status_code),
        error_class = "http_error",
        error_message = sprintf("HTTP status %s", status_code)
      ))
    }

    file_size <- file.info(staging_path)$size

    if (is.na(file_size) || file_size <= 0) {
      unlink(staging_path)
      return(list(
        success = FALSE,
        attempt_count = attempt,
        http_status = as.integer(status_code),
        error_class = "empty_download",
        error_message = "Download response produced an empty file."
      ))
    }

    retain_staging_file <- TRUE

    return(list(
      success = TRUE,
      attempt_count = attempt,
      http_status = as.integer(status_code),
      staging_path = staging_path,
      file_size_bytes = as.numeric(file_size),
      sha256 = calculate_sha256(staging_path)
    ))
  }
}

#' Read compatible successful log entries for a raw-data destination.
#'
#' @param log_path Download-log path.
#' @param resource One-row catalog tibble.
#' @param destination_path Project-relative destination path.
#' @return Matching successful log rows.
read_compatible_log_entries <- function(log_path, resource, destination_path) {
  if (!file.exists(log_path)) {
    return(tibble::tibble())
  }

  validate_existing_download_log(log_path)
  log_data <- read_download_log(log_path)

  dplyr::filter(
    log_data,
    .data$event_type == "resource_result",
    .data$outcome %in% c("downloaded", "skipped_existing_verified"),
    .data$resource_id == resource$resource_id,
    .data$download_url == resource$download_url,
    .data$local_filename == resource$local_filename,
    .data$destination_path == destination_path,
    !is.na(.data$sha256)
  )
}

#' Verify whether an existing raw file can be safely reused.
#'
#' @param destination Absolute raw-file path.
#' @param compatible_entries Successful matching log entries.
#' @return TRUE only when size and SHA-256 match a logged entry.
is_existing_file_verified <- function(destination, compatible_entries) {
  if (!file.exists(destination) || nrow(compatible_entries) == 0L) {
    return(FALSE)
  }

  file_size <- as.numeric(file.info(destination)$size)
  file_hash <- calculate_sha256(destination)

  any(
    compatible_entries$file_size_bytes == file_size &
      compatible_entries$sha256 == file_hash
  )
}

#' Publish a verified staged file without exposing an incomplete final filename.
#'
#' @param staged_path Verified external staging path.
#' @param destination Final raw-file path.
#' @param expected_size Expected file size.
#' @param expected_sha256 Expected SHA-256 checksum.
#' @param resource_id Catalog resource identifier.
#' @param run_id Current run identifier.
#' @param raw_directory Configured raw-data directory.
#' @return Result list describing publication success or failure.
publish_verified_file <- function(
  staged_path,
  destination,
  expected_size,
  expected_sha256,
  resource_id,
  run_id,
  raw_directory
) {
  if (file.exists(destination)) {
    return(list(success = FALSE, outcome = "conflict_existing_file", error_class = "existing_file"))
  }

  publication_temporary <- build_publication_temporary_path(raw_directory, resource_id, run_id)
  on.exit(unlink(publication_temporary), add = TRUE)

  if (file.exists(publication_temporary) || !file.copy(staged_path, publication_temporary)) {
    return(list(success = FALSE, outcome = "failed_integrity", error_class = "publication_copy"))
  }

  temporary_size <- as.numeric(file.info(publication_temporary)$size)
  temporary_hash <- calculate_sha256(publication_temporary)

  if (!identical(temporary_size, expected_size) || !identical(temporary_hash, expected_sha256)) {
    return(list(success = FALSE, outcome = "failed_integrity", error_class = "publication_verification"))
  }

  if (file.exists(destination) || !file.rename(publication_temporary, destination)) {
    return(list(success = FALSE, outcome = "conflict_existing_file", error_class = "publication_rename"))
  }

  list(success = TRUE)
}

#' Process one eligible catalog resource and create its terminal log event.
#'
#' @param resource One-row catalog tibble.
#' @param config Download-specific configuration.
#' @param run_id Current run identifier.
#' @return One-row terminal download-log event.
process_resource <- function(resource, config, run_id) {
  destination_path <- build_destination_path(config$raw_directory, resource$local_filename)
  destination <- file.path(getwd(), destination_path)
  log_event <- new_log_event("resource_result", run_id, "failed_download")
  log_event$resource_id <- resource$resource_id
  log_event$download_url <- resource$download_url
  log_event$local_filename <- resource$local_filename
  log_event$destination_path <- destination_path

  compatible_entries <- read_compatible_log_entries(
    config$log_path,
    resource,
    destination_path
  )

  if (file.exists(destination)) {
    if (is_existing_file_verified(destination, compatible_entries)) {
      log_event$outcome <- "skipped_existing_verified"
      log_event$file_size_bytes <- as.numeric(file.info(destination)$size)
      log_event$sha256 <- calculate_sha256(destination)
      log_event$attempt_count <- 0L
      return(log_event)
    }

    log_event$outcome <- "conflict_existing_file"
    log_event$error_class <- "existing_file"
    log_event$error_message <- "Existing raw file has no compatible verified log entry."
    log_event$attempt_count <- 0L
    return(log_event)
  }

  download_result <- download_to_staging(resource, config, run_id)
  log_event$attempt_count <- download_result$attempt_count
  log_event$http_status <- download_result$http_status

  if (!isTRUE(download_result$success)) {
    log_event$outcome <- "failed_download"
    log_event$error_class <- download_result$error_class
    log_event$error_message <- download_result$error_message
    return(log_event)
  }

  on.exit(unlink(download_result$staging_path), add = TRUE)
  publication_result <- publish_verified_file(
    staged_path = download_result$staging_path,
    destination = destination,
    expected_size = download_result$file_size_bytes,
    expected_sha256 = download_result$sha256,
    resource_id = resource$resource_id,
    run_id = run_id,
    raw_directory = config$raw_directory
  )

  if (!isTRUE(publication_result$success)) {
    log_event$outcome <- publication_result$outcome
    log_event$error_class <- publication_result$error_class
    log_event$error_message <- "Verified staging file could not be published."
    return(log_event)
  }

  log_event$outcome <- "downloaded"
  log_event$file_size_bytes <- download_result$file_size_bytes
  log_event$sha256 <- download_result$sha256
  log_event
}

#' Execute the complete exclusive download acquisition contract.
#'
#' @return Invisibly returns TRUE when every resource succeeds.
main <- function() {
  config <- read_project_config("config/project.yml")
  download_config <- validate_download_config(config)
  run_id <- create_run_id()

  acquire_download_lock(download_config$lock_path, run_id)
  on.exit(release_download_lock(download_config$lock_path), add = TRUE)

  ensure_directory(download_config$raw_directory, "raw-data directory")
  ensure_directory(download_config$staging_directory, "download staging directory")

  append_download_log_event(
    new_log_event("run_started", run_id, "started"),
    download_config$log_path
  )

  preflight <- tryCatch(
    {
      residual_temporaries <- find_residual_publication_temporaries(download_config$raw_directory)

      if (length(residual_temporaries) > 0L) {
        abort_download(
          sprintf(
            "Residual publication temporary detected in raw data: %s. Inspect it manually.",
            paste(residual_temporaries, collapse = ", ")
          )
        )
      }

      read_eligible_catalog(download_config$catalog_path)
    },
    error = function(error) error
  )

  if (inherits(preflight, "error")) {
    failure_event <- new_log_event("run_failed_preflight", run_id, "failed_preflight")
    failure_event$error_class <- "preflight"
    failure_event$error_message <- sanitize_error_message(conditionMessage(preflight))
    append_download_log_event(failure_event, download_config$log_path)
    abort_download(conditionMessage(preflight))
  }

  resource_events <- purrr::map_dfr(
    seq_len(nrow(preflight)),
    function(index) {
      event <- tryCatch(
        process_resource(preflight[index, ], download_config, run_id),
        error = function(error) {
          failed_event <- new_log_event("resource_result", run_id, "failed_download")
          failed_event$resource_id <- preflight$resource_id[[index]]
          failed_event$download_url <- preflight$download_url[[index]]
          failed_event$local_filename <- preflight$local_filename[[index]]
          failed_event$destination_path <- build_destination_path(
            download_config$raw_directory,
            preflight$local_filename[[index]]
          )
          failed_event$attempt_count <- 0L
          failed_event$error_class <- "unexpected_error"
          failed_event$error_message <- sanitize_error_message(conditionMessage(error))
          failed_event
        }
      )

      append_download_log_event(event, download_config$log_path)
      event
    }
  )

  failures <- sum(!resource_events$outcome %in% c("downloaded", "skipped_existing_verified"))
  run_outcome <- if (failures == 0L) "completed" else "completed_with_failures"
  append_download_log_event(
    new_log_event("run_finished", run_id, run_outcome),
    download_config$log_path
  )

  invisible(failures == 0L)
}

#' Determine whether this file is the direct Rscript input file.
#'
#' @return TRUE only when 01_download_data.R is executed directly.
is_direct_script_execution <- function() {
  command_arguments <- commandArgs(trailingOnly = FALSE)
  file_arguments <- command_arguments[startsWith(command_arguments, "--file=")]

  length(file_arguments) == 1L && identical(
    basename(sub("^--file=", "", file_arguments)),
    "01_download_data.R"
  )
}

if (is_direct_script_execution()) {
  succeeded <- main()

  if (!isTRUE(succeeded)) {
    quit(status = 1L)
  }
}
