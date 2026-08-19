###############################################################
# Argentina Dengue Analysis
# Script: 04_harmonize_canonical_resources.R
# Purpose: Structurally harmonize authorized canonical CSV records.
# Inputs: project configuration, canonical manifest, validation snapshot, raw CSVs.
# Output: deterministic structural records in data/processed/.
###############################################################

structural_columns <- c(
  "source_resource_id", "source_local_filename", "source_row_number",
  "source_schema_family", "province_id", "province_name", "department_id",
  "department_name", "source_year", "source_week", "event",
  "source_age_group_id", "source_age_group_label", "source_case_count"
)

#' Stop structural harmonization with a contract-specific error.
#'
#' @param message Error message.
#' @return This function does not return.
abort_harmonization <- function(message) {
  stop(message, call. = FALSE)
}

#' Read the project configuration from its fixed bootstrap path.
#'
#' @return Parsed YAML configuration.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) {
    abort_harmonization("Configuration file not found: config/project.yml")
  }
  tryCatch(
    yaml::read_yaml("config/project.yml"),
    error = function(error) abort_harmonization(sprintf("Could not read configuration: %s", error$message))
  )
}

#' Get a required scalar configuration string.
#'
#' @param config Parsed configuration.
#' @param section First-level section.
#' @param key Required key.
#' @return Trimmed string.
required_string <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (is.null(value) || length(value) != 1L || !is.character(value) || is.na(value) || !nzchar(trimws(value))) {
    abort_harmonization(sprintf("Missing or invalid configuration value: %s.%s", section, key))
  }
  trimws(value)
}

#' Require a path to be project-relative.
#'
#' @param path Configured path.
#' @param label Configuration label.
#' @return Invisibly returns path.
require_relative_path <- function(path, label) {
  if (grepl("^(/|[[:alpha:]]:[/\\\\])", path)) {
    abort_harmonization(sprintf("%s must be relative to the project root: %s", label, path))
  }
  invisible(path)
}

#' Determine whether a path belongs to a project-relative directory.
#'
#' @param path Candidate path.
#' @param directory Parent directory.
#' @return Logical scalar.
inside_directory <- function(path, directory) {
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidate <- normalizePath(file.path(root, path), winslash = "/", mustWork = FALSE)
  parent <- normalizePath(file.path(root, directory), winslash = "/", mustWork = FALSE)
  startsWith(candidate, paste0(parent, "/"))
}

#' Validate configuration required by structural harmonization.
#'
#' @param config Parsed configuration.
#' @return Named list of validated settings.
harmonization_config <- function(config) {
  paths <- list(
    raw_directory = required_string(config, "directories", "raw_data"),
    metadata_directory = required_string(config, "directories", "metadata"),
    processed_directory = required_string(config, "directories", "processed_data"),
    canonical_path = required_string(config, "artifacts", "canonical_resources"),
    snapshot_path = required_string(config, "artifacts", "validation_snapshot"),
    output_path = required_string(config, "artifacts", "canonical_resources_structural")
  )
  purrr::iwalk(paths, require_relative_path)
  if (!inside_directory(paths$canonical_path, paths$metadata_directory) || !inside_directory(paths$snapshot_path, paths$metadata_directory)) {
    abort_harmonization("Canonical manifest and validation snapshot must belong to the metadata directory.")
  }
  if (!inside_directory(paths$output_path, paths$processed_directory)) {
    abort_harmonization("Structural harmonization output must belong to the processed-data directory.")
  }
  encodings <- config$harmonization$body_encodings
  if (!identical(encodings, c("UTF-8", "latin1"))) {
    abort_harmonization("harmonization.body_encodings must be exactly UTF-8 followed by latin1.")
  }
  c(paths, list(body_encodings = encodings))
}

#' Read and validate the canonical resource-selection manifest.
#'
#' @param path Canonical manifest path.
#' @return Authorized canonical resources.
read_canonical_manifest <- function(path) {
  columns <- c("canonical_selection_schema_version", "resource_id", "local_filename", "coverage_start_year", "coverage_start_week", "coverage_end_year", "coverage_end_week", "coverage_week_count", "coverage_signature", "source_last_modified_at", "competition_count", "selection_status", "selection_reason", "superseded_by_resource_id", "processing_authorized")
  manifest <- readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character(), processing_authorized = readr::col_logical()))
  if (!identical(names(manifest), columns) || nrow(readr::problems(manifest)) || any(manifest$canonical_selection_schema_version != "1.0.0") || anyDuplicated(manifest$resource_id)) {
    abort_harmonization("Canonical manifest does not satisfy canonical_resource_selection contract 1.0.0.")
  }
  authorized <- dplyr::filter(manifest, .data$processing_authorized %in% TRUE)
  if (!nrow(authorized) || any(!nzchar(authorized$resource_id)) || any(!nzchar(authorized$local_filename))) {
    abort_harmonization("Canonical manifest has no valid processing-authorized resources.")
  }
  authorized
}

#' Read and validate the validation snapshot contract.
#'
#' @param path Validation snapshot path.
#' @return Typed snapshot tibble.
read_validation_snapshot <- function(path) {
  columns <- c("validation_schema_version", "validation_run_id", "validated_at_utc", "record_type", "record_key", "resource_id", "eligible_for_download", "download_url", "local_filename", "destination_path", "provenance_event_type", "provenance_run_id", "provenance_event_at_utc", "provenance_evidence_count", "expected_file_size_bytes", "expected_sha256", "observed_file_size_bytes", "observed_sha256", "physical_status", "provenance_status", "readability_status", "csv_delimiter", "csv_column_count", "validation_outcome", "diagnostic_code", "processing_eligible")
  snapshot <- readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character(), eligible_for_download = readr::col_logical(), processing_eligible = readr::col_logical(), csv_column_count = readr::col_integer()))
  if (!identical(names(snapshot), columns) || nrow(readr::problems(snapshot)) || any(snapshot$validation_schema_version != "1.0.0")) {
    abort_harmonization("Validation snapshot does not satisfy validation_snapshot contract 1.0.0.")
  }
  snapshot
}

#' Retrieve exactly one compatible snapshot row for an authorized resource.
#'
#' @param resource One canonical manifest row.
#' @param snapshot Validated validation snapshot.
#' @return One snapshot row.
compatible_snapshot_row <- function(resource, snapshot) {
  rows <- dplyr::filter(snapshot, .data$record_type == "catalog_resource", .data$resource_id == resource$resource_id, .data$local_filename == resource$local_filename)
  if (nrow(rows) != 1L || !isTRUE(rows$processing_eligible) || rows$physical_status != "passed" || rows$provenance_status != "passed" || rows$readability_status != "passed" || !rows$csv_delimiter %in% c("comma", "semicolon", "tab")) {
    abort_harmonization(sprintf("Validation evidence is missing, duplicated, or incompatible for resource: %s", resource$resource_id))
  }
  rows
}

#' Convert a contractual delimiter label into its literal character.
#'
#' @param delimiter Contractual delimiter label.
#' @return Literal delimiter.
delimiter_character <- function(delimiter) {
  value <- c(comma = ",", semicolon = ";", tab = "\t")[[delimiter]]
  if (is.null(value)) abort_harmonization(sprintf("Unsupported contractual delimiter: %s", delimiter))
  value
}

#' Read source bytes without changing the raw file.
#'
#' @param path Raw source path.
#' @return Raw vector.
read_source_bytes <- function(path) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) {
    abort_harmonization(sprintf("Raw source file is missing or not regular: %s", path))
  }
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = file.info(path)$size)
}

#' Exclude only the approved terminal DOS transport marker from logical payload.
#'
#' @param bytes Complete raw source bytes.
#' @param resource_id Resource identifier for diagnostics.
#' @return List with logical payload and marker flag.
logical_csv_payload <- function(bytes, resource_id) {
  marker_positions <- which(as.integer(bytes) == 26L)
  if (!length(marker_positions)) return(list(bytes = bytes, terminal_marker = FALSE))
  valid_marker <- length(marker_positions) == 1L && marker_positions[[1]] == length(bytes) && length(bytes) > 1L && as.integer(bytes[[length(bytes) - 1L]]) == 10L
  if (!valid_marker) {
    abort_harmonization(sprintf("Invalid 0x1A transport-marker placement in resource: %s", resource_id))
  }
  list(bytes = bytes[-length(bytes)], terminal_marker = TRUE)
}

#' Select encoding deterministically from the logical complete payload.
#'
#' @param payload Logical CSV payload bytes.
#' @param encodings Ordered configured body encodings.
#' @return Encoding name.
payload_encoding <- function(payload, encodings) {
  as_text <- rawToChar(payload)
  if (!is.na(iconv(as_text, from = encodings[[1]], to = "UTF-8", sub = NA_character_))) encodings[[1]] else encodings[[2]]
}

#' Read an in-memory logical payload as a CSV with source columns as text.
#'
#' @param payload Logical raw payload.
#' @param delimiter Literal CSV delimiter.
#' @param encoding Selected decoding encoding.
#' @param resource_id Resource identifier for diagnostics.
#' @return Parsed source data tibble.
read_source_csv <- function(payload, delimiter, encoding, resource_id) {
  connection <- rawConnection(payload, open = "rb")
  on.exit(try(close(connection), silent = TRUE), add = TRUE)
  source <- tryCatch(
    readr::read_delim(connection, delim = delimiter, locale = readr::locale(encoding = encoding), col_types = readr::cols(.default = readr::col_character()), name_repair = "minimal", show_col_types = FALSE),
    error = function(error) abort_harmonization(sprintf("Could not parse resource %s: %s", resource_id, error$message))
  )
  if (nrow(readr::problems(source)) || anyDuplicated(names(source))) {
    abort_harmonization(sprintf("CSV parsing or column-name validation failed for resource: %s", resource_id))
  }
  source
}

#' Identify one source-schema family solely from an exact column signature.
#'
#' @param columns Parsed source column names.
#' @return List with family and source-to-output mapping.
identify_schema_family <- function(columns) {
  generic_prefix <- c("departamento_id", "departamento_nombre", "provincia_id", "provincia_nombre")
  generic_suffix <- c("semanas_epidemiologicas", "evento_nombre", "grupo_edad_id", "grupo_edad_desc", "cantidad_casos")
  generic_matches <- vapply(c("ano", "año"), function(year_column) identical(columns, c(generic_prefix, year_column, generic_suffix)), logical(1))
  indec_columns <- c("id_depto_indec_residencia", "departamento_residencia", "id_prov_indec_residencia", "provincia_residencia", "anio_min", "evento", "id_grupo_etario", "grupo_etario", "sepi_min", "cantidad")
  indec_matches <- identical(columns, indec_columns)
  if (sum(generic_matches) + as.integer(indec_matches) != 1L) {
    abort_harmonization("Source columns do not match exactly one structural-harmonization schema family.")
  }
  if (indec_matches) {
    return(list(family = "indec_residence_geography", mapping = c(province_id = "id_prov_indec_residencia", province_name = "provincia_residencia", department_id = "id_depto_indec_residencia", department_name = "departamento_residencia", source_year = "anio_min", source_week = "sepi_min", event = "evento", source_age_group_id = "id_grupo_etario", source_age_group_label = "grupo_etario", source_case_count = "cantidad")))
  }
  year_column <- c("ano", "año")[generic_matches][[1]]
  list(family = "generic_geography", mapping = c(province_id = "provincia_id", province_name = "provincia_nombre", department_id = "departamento_id", department_name = "departamento_nombre", source_year = year_column, source_week = "semanas_epidemiologicas", event = "evento_nombre", source_age_group_id = "grupo_edad_id", source_age_group_label = "grupo_edad_desc", source_case_count = "cantidad_casos"))
}

#' Parse source numeric text with a strict decimal-integer rule.
#'
#' @param values Source character values.
#' @param field Output-field label.
#' @param minimum Minimum accepted integer.
#' @param maximum Optional maximum accepted integer.
#' @param resource_id Resource identifier for diagnostics.
#' @return Integer vector.
parse_strict_integer <- function(values, field, minimum, maximum = Inf, resource_id) {
  if (any(is.na(values)) || any(!grepl("^[0-9]+$", values))) {
    abort_harmonization(sprintf("%s is missing or not a decimal integer in resource: %s", field, resource_id))
  }
  parsed <- suppressWarnings(as.integer(values))
  if (any(is.na(parsed)) || any(parsed < minimum | parsed > maximum)) {
    abort_harmonization(sprintf("%s is outside its contractual range in resource: %s", field, resource_id))
  }
  parsed
}

#' Harmonize one canonical source resource without changing source text values.
#'
#' @param resource One authorized canonical manifest row.
#' @param snapshot Compatible validation snapshot row.
#' @param raw_directory Configured raw-data directory.
#' @param body_encodings Ordered configured body encodings.
#' @return List containing output rows and run diagnostics.
harmonize_resource <- function(resource, snapshot, raw_directory, body_encodings) {
  path <- file.path(raw_directory, resource$local_filename)
  payload_info <- logical_csv_payload(read_source_bytes(path), resource$resource_id)
  encoding <- payload_encoding(payload_info$bytes, body_encodings)
  source <- read_source_csv(payload_info$bytes, delimiter_character(snapshot$csv_delimiter), encoding, resource$resource_id)
  schema <- identify_schema_family(names(source))
  mapping <- schema$mapping
  rows <- tibble::tibble(
    source_resource_id = resource$resource_id,
    source_local_filename = resource$local_filename,
    source_row_number = seq_len(nrow(source)),
    source_schema_family = schema$family,
    province_id = source[[mapping[["province_id"]]]],
    province_name = source[[mapping[["province_name"]]]],
    department_id = source[[mapping[["department_id"]]]],
    department_name = source[[mapping[["department_name"]]]],
    source_year = parse_strict_integer(source[[mapping[["source_year"]]]], "source_year", 1000L, 9999L, resource$resource_id),
    source_week = parse_strict_integer(source[[mapping[["source_week"]]]], "source_week", 1L, 53L, resource$resource_id),
    event = source[[mapping[["event"]]]],
    source_age_group_id = source[[mapping[["source_age_group_id"]]]],
    source_age_group_label = source[[mapping[["source_age_group_label"]]]],
    source_case_count = parse_strict_integer(source[[mapping[["source_case_count"]]]], "source_case_count", 0L, resource_id = resource$resource_id)
  )
  list(rows = rows, encoding = encoding, schema_family = schema$family, delimiter = snapshot$csv_delimiter, source_records = nrow(source), terminal_marker = payload_info$terminal_marker)
}

#' Validate cross-resource preservation invariants before publication.
#'
#' @param rows Completed structural rows.
#' @param expected_rows Sum of source-record counts.
#' @return Invisibly TRUE when valid.
validate_output_invariants <- function(rows, expected_rows) {
  if (!identical(names(rows), structural_columns) || nrow(rows) != expected_rows || anyDuplicated(rows[c("source_resource_id", "source_row_number")]) || any(rows$source_row_number < 1L) || any(rows$source_week < 1L | rows$source_week > 53L) || any(rows$source_case_count < 0L)) {
    abort_harmonization("Structural-harmonization preservation invariants failed.")
  }
  per_resource <- dplyr::group_by(rows, .data$source_resource_id)
  if (any(dplyr::summarise(per_resource, sequential = identical(.data$source_row_number, seq_len(dplyr::n())), .groups = "drop")$sequential %in% FALSE)) {
    abort_harmonization("Source row numbers are not sequential within a resource.")
  }
  invisible(TRUE)
}

#' Atomically publish the completed structural artifact.
#'
#' @param rows Completed validated structural rows.
#' @param output_path Configured artifact path.
#' @return Invisibly TRUE on success.
publish_structural_rows <- function(rows, output_path) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(".argentina_dengue_harmonization_", dirname(output_path), ".csv")
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(rows, temporary, na = "")
  if (!file.rename(temporary, output_path)) {
    abort_harmonization("Could not atomically publish structural harmonization output.")
  }
  invisible(TRUE)
}

#' Run structural harmonization from the project root.
#'
#' @return Invisibly TRUE on success.
main <- function() {
  config <- harmonization_config(read_project_config())
  canonical <- read_canonical_manifest(config$canonical_path)
  snapshot <- read_validation_snapshot(config$snapshot_path)
  if (!dir.exists(config$raw_directory)) abort_harmonization("Configured raw-data directory does not exist.")
  results <- purrr::map(seq_len(nrow(canonical)), function(index) {
    resource <- canonical[index, ]
    harmonize_resource(resource, compatible_snapshot_row(resource, snapshot), config$raw_directory, config$body_encodings)
  })
  rows <- dplyr::arrange(dplyr::bind_rows(purrr::map(results, "rows")), .data$source_resource_id, .data$source_row_number)
  validate_output_invariants(rows, sum(vapply(results, `[[`, integer(1), "source_records")))
  purrr::walk2(canonical$resource_id, results, function(resource_id, result) {
    message(sprintf("%s | family=%s | delimiter=%s | encoding=%s | source_records=%s | output_rows=%s | terminal_0x1A=%s", resource_id, result$schema_family, result$delimiter, result$encoding, result$source_records, nrow(result$rows), result$terminal_marker))
  })
  publish_structural_rows(rows, config$output_path)
  invisible(TRUE)
}

if (length(commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]) == 1L && basename(sub("^--file=", "", commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")])) == "04_harmonize_canonical_resources.R") {
  main()
}
