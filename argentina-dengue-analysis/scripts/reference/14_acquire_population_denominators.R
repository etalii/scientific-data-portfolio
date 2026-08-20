###############################################################
# Argentina Dengue Analysis
# Script: 14_acquire_population_denominators.R
# Purpose: Acquire and normalize validated INDEC population references.
###############################################################

population_provenance_columns <- c(
  "population_provenance_schema_version", "source_resource_identifier",
  "projection_vintage", "acquisition_mode", "origin_verification_status",
  "source_authority", "source_title", "source_landing_url",
  "source_download_url", "source_format", "source_sha256",
  "source_publication_date", "acquired_at_utc", "local_filename"
)

population_denominator_columns <- c(
  "population_schema_version", "source_resource_identifier", "geography_level",
  "population_year", "province_reference_id", "province_reference_name",
  "population", "population_scope", "projection_vintage", "census_basis",
  "reference_date"
)

#' Abort C.14 with one explicit, actionable error.
abort_population_reference <- function(message) stop(message, call. = FALSE)

#' Read the central project configuration from the project root.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) {
    abort_population_reference("Configuration file not found: config/project.yml")
  }
  tryCatch(
    yaml::read_yaml("config/project.yml"),
    error = function(error) abort_population_reference(error$message)
  )
}

#' Read one safe, non-empty project-relative configured path.
configured_path <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (!is.character(value) || length(value) != 1L || is.na(value) || !nzchar(value) ||
      grepl("^(/|[[:alpha:]]:[/\\\\])", value)) {
    abort_population_reference(sprintf("Invalid configuration path: %s.%s", section, key))
  }
  value
}

#' Validate the configured population source specifications.
read_population_sources <- function(config) {
  sources <- config$population_reference$sources
  required_years <- config$population_reference$required_years
  if (!is.list(sources) || !is.list(required_years) || !length(sources)) {
    abort_population_reference("population_reference source configuration is missing or invalid.")
  }

  required_fields <- c(
    "source_resource_identifier", "source_authority", "source_title",
    "source_landing_url", "expected_filename", "accepted_formats", "census_basis",
    "workbook"
  )
  for (vintage in names(sources)) {
    source <- sources[[vintage]]
    if (!all(required_fields %in% names(source)) || is.null(required_years[[vintage]])) {
      abort_population_reference(sprintf("Incomplete configuration for projection vintage: %s", vintage))
    }
    if (!identical(source$source_authority, "INDEC") ||
        !is.character(source$expected_filename) || length(source$expected_filename) != 1L ||
        !nzchar(source$expected_filename) || grepl("[/\\\\]", source$expected_filename)) {
      abort_population_reference(sprintf("Invalid official identity for projection vintage: %s", vintage))
    }
    required <- as.integer(unlist(required_years[[vintage]], use.names = FALSE))
    workbook <- source$workbook
    if (!length(required) || any(is.na(required)) ||
        !all(c("national_sheet", "province_sheet_pattern", "header_skip", "required_columns") %in% names(workbook)) ||
        !identical(workbook$required_columns, c("Año", "Ambos sexos", "Varones", "Mujeres"))) {
      abort_population_reference(sprintf("Invalid workbook specification for projection vintage: %s", vintage))
    }
  }
  sources
}

#' Calculate a lowercase SHA-256 checksum with deterministic connection cleanup.
calculate_sha256 <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection), collapse = "")
}

#' Require a URL host controlled by INDEC.
is_official_indec_url <- function(url) {
  host <- sub("^https?://([^/:]+).*$", "\\1", url, ignore.case = TRUE)
  grepl("(^|\\.)indec\\.gob\\.ar$", host, ignore.case = TRUE)
}

#' Convert an official relative link into an official absolute URL.
absolute_indec_url <- function(url, base_url) {
  if (grepl("^https://", url, ignore.case = TRUE)) return(url)
  origin <- sub("^(https://[^/]+).*$", "\\1", base_url, ignore.case = TRUE)
  if (!grepl("^https://", origin, ignore.case = TRUE)) {
    abort_population_reference("The official landing URL must use HTTPS.")
  }
  paste0(origin, if (startsWith(url, "/")) "" else "/", url)
}

#' Retrieve an official text response without weakening TLS or HTTP validation.
download_text <- function(url) {
  response <- tryCatch(
    httr2::request(url) |> httr2::req_timeout(60) |> httr2::req_perform(),
    error = function(error) abort_population_reference(sprintf("Official source request failed: %s", error$message))
  )
  if (httr2::resp_status(response) < 200L || httr2::resp_status(response) >= 300L) {
    abort_population_reference(sprintf("Official source returned HTTP %s: %s", httr2::resp_status(response), url))
  }
  httr2::resp_body_string(response)
}

#' Resolve the page fragment published by INDEC's single-page application.
resolve_indec_content <- function(landing_url) {
  landing <- download_text(landing_url)
  dynamic_path <- regmatches(
    landing,
    regexpr('id="VistaCarga" value="[^"]+"', landing, perl = TRUE)
  )
  if (!length(dynamic_path) || !nzchar(dynamic_path)) return(landing)
  dynamic_path <- sub('^id="VistaCarga" value="([^"]+)"$', "\\1", dynamic_path)
  download_text(absolute_indec_url(dynamic_path, landing_url))
}

#' Resolve an exact, published official download link for one source.
resolve_official_download_url <- function(source) {
  content <- resolve_indec_content(source$source_landing_url)
  hrefs <- unlist(regmatches(content, gregexpr('href="[^"]+"', content, perl = TRUE)))
  hrefs <- sub('"$', "", sub('^href="', "", hrefs))
  matches <- hrefs[basename(hrefs) == source$expected_filename]
  if (length(matches) != 1L) {
    abort_population_reference(sprintf(
      "Could not resolve exactly one published download URL for %s.",
      source$source_resource_identifier
    ))
  }
  url <- absolute_indec_url(matches, source$source_landing_url)
  if (!is_official_indec_url(url)) {
    abort_population_reference("Resolved download URL is not hosted by official INDEC.")
  }
  url
}

#' Download one official file to operational staging without publishing it.
download_online_source <- function(source, staging_directory) {
  download_url <- resolve_official_download_url(source)
  temporary <- tempfile(".population_online_", tmpdir = staging_directory, fileext = paste0(".", tools::file_ext(source$expected_filename)))
  response <- tryCatch(
    httr2::request(download_url) |> httr2::req_timeout(120) |> httr2::req_perform(path = temporary),
    error = function(error) {
      unlink(temporary)
      abort_population_reference(sprintf("Official file download failed: %s", error$message))
    }
  )
  if (httr2::resp_status(response) < 200L || httr2::resp_status(response) >= 300L ||
      !file.exists(temporary) || file.size(temporary) <= 0L) {
    unlink(temporary)
    abort_population_reference(sprintf("Official download is empty or returned HTTP %s.", httr2::resp_status(response)))
  }
  list(path = temporary, acquisition_mode = "online_download",
       origin_verification_status = "official_host_download", source_download_url = download_url,
       cleanup_after_run = TRUE)
}

#' Locate an original externally supplied file with the configured identity.
find_external_source <- function(source, staging_directory) {
  candidate <- file.path(staging_directory, source$expected_filename)
  if (!file.exists(candidate)) return(NULL)
  list(path = candidate, acquisition_mode = "external_raw",
       origin_verification_status = "external_origin_not_cryptographically_verified",
       source_download_url = NA_character_, cleanup_after_run = FALSE)
}

#' Read and validate the fixed C1 workbook layout observed in the official sources.
read_population_sheet <- function(path, sheet, workbook, vintage) {
  rows <- tryCatch(
    readxl::read_excel(path, sheet = sheet, skip = workbook$header_skip),
    error = function(error) abort_population_reference(sprintf("Could not read %s/%s: %s", vintage, sheet, error$message))
  )
  if (!identical(names(rows), workbook$required_columns)) {
    abort_population_reference(sprintf("Unexpected C1 columns in %s/%s.", vintage, sheet))
  }
  source_note <- !is.na(rows$Año) & grepl("^Fuente: INDEC[,\\.]", rows$Año)
  blank_row <- is.na(rows$Año) & is.na(rows[["Ambos sexos"]]) & is.na(rows$Varones) & is.na(rows$Mujeres)
  invalid_row <- !(source_note | blank_row | grepl("^[0-9]{4}$", rows$Año))
  if (any(invalid_row) || any(source_note & (!is.na(rows[["Ambos sexos"]]) | !is.na(rows$Varones) | !is.na(rows$Mujeres)))) {
    abort_population_reference(sprintf("Unexpected non-tabular row in %s/%s.", vintage, sheet))
  }
  rows <- rows[grepl("^[0-9]{4}$", rows$Año), , drop = FALSE]
  rows$Año <- as.integer(rows$Año)
  numeric_columns <- c("Ambos sexos", "Varones", "Mujeres")
  if (!nrow(rows) || any(rows$Año < 2010L | rows$Año > 2040L) ||
      any(vapply(rows[numeric_columns], function(column) any(is.na(column) | column <= 0 | column != floor(column)), logical(1)))) {
    abort_population_reference(sprintf("Invalid population values in %s/%s.", vintage, sheet))
  }
  if (anyDuplicated(rows$Año)) {
    abort_population_reference(sprintf("Duplicate population years in %s/%s.", vintage, sheet))
  }
  rows
}

#' Validate and normalize one C1 workbook using only published total-both-sexes cells.
normalize_population_workbook <- function(path, vintage, source, required_years) {
  if (tools::file_ext(path) != source$accepted_formats[[1L]]) {
    abort_population_reference(sprintf("Unexpected format for %s: %s", vintage, basename(path)))
  }
  workbook <- source$workbook
  sheets <- tryCatch(readxl::excel_sheets(path), error = function(error) abort_population_reference(error$message))
  province_sheets <- sheets[grepl(workbook$province_sheet_pattern, sheets, perl = TRUE)]
  province_sheets <- setdiff(province_sheets, workbook$national_sheet)
  if (!identical(sheets[match(workbook$national_sheet, sheets)], workbook$national_sheet) ||
      length(province_sheets) != 24L || anyDuplicated(substr(province_sheets, 1L, 2L))) {
    abort_population_reference(sprintf("Unexpected C1 workbook sheet structure for %s.", vintage))
  }

  parse_sheet <- function(sheet, geography_level, province_id = NA_character_, province_name = NA_character_) {
    rows <- read_population_sheet(path, sheet, workbook, vintage)
    selected <- rows[rows$Año %in% required_years, , drop = FALSE]
    if (nrow(selected) != length(required_years) || !setequal(selected$Año, required_years)) {
      abort_population_reference(sprintf("Required population years are missing from %s/%s.", vintage, sheet))
    }
    tibble::tibble(
      population_schema_version = "1.0.0",
      source_resource_identifier = source$source_resource_identifier,
      geography_level = geography_level,
      population_year = selected$Año,
      province_reference_id = province_id,
      province_reference_name = province_name,
      population = as.numeric(selected[["Ambos sexos"]]),
      population_scope = "total_both_sexes",
      projection_vintage = vintage,
      census_basis = source$census_basis,
      reference_date = sprintf("%d-07-01", selected$Año)
    )
  }

  national <- parse_sheet(workbook$national_sheet, "national")
  provinces <- dplyr::bind_rows(lapply(province_sheets, function(sheet) {
    parse_sheet(sheet, "province", substr(sheet, 1L, 2L), sub("^[0-9]{2}-", "", sheet))
  }))
  output <- dplyr::bind_rows(national, provinces) |>
    dplyr::arrange(.data$population_year, .data$geography_level, .data$province_reference_id)
  if (nrow(provinces) != length(required_years) * 24L ||
      anyDuplicated(output[c("projection_vintage", "population_year", "geography_level", "province_reference_id")])) {
    abort_population_reference(sprintf("Invalid jurisdiction cardinality for %s.", vintage))
  }
  output
}

#' Read existing provenance or return an empty table with its contractual schema.
read_population_provenance <- function(path) {
  if (!file.exists(path)) return(tibble::as_tibble(stats::setNames(replicate(length(population_provenance_columns), character(), simplify = FALSE), population_provenance_columns)))
  rows <- tryCatch(readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())), error = function(error) abort_population_reference(error$message))
  if (!identical(names(rows), population_provenance_columns) || nrow(readr::problems(rows))) {
    abort_population_reference("Existing population provenance does not satisfy its contract.")
  }
  rows
}

#' Verify a prior raw publication against its immutable provenance record.
reuse_existing_source <- function(source, vintage, provenance, raw_directory) {
  record <- provenance[provenance$projection_vintage == vintage, , drop = FALSE]
  if (!nrow(record)) return(NULL)
  if (nrow(record) != 1L || record$source_resource_identifier != source$source_resource_identifier ||
      !grepl("^[0-9a-f]{64}$", record$source_sha256) || grepl("[/\\\\]", record$local_filename)) {
    abort_population_reference(sprintf("Invalid existing provenance for %s.", vintage))
  }
  path <- file.path(raw_directory, record$local_filename)
  if (!file.exists(path) || calculate_sha256(path) != record$source_sha256) {
    abort_population_reference(sprintf("Existing raw population file conflicts with provenance for %s.", vintage))
  }
  list(path = path, provenance = record, existing = TRUE)
}

#' Atomically publish verified bytes to immutable population raw storage.
publish_raw_file <- function(input_path, destination, expected_sha256) {
  directory <- dirname(destination)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  if (file.exists(destination)) {
    if (calculate_sha256(destination) != expected_sha256) abort_population_reference(sprintf("Immutable raw conflict: %s", destination))
    return(invisible(destination))
  }
  temporary <- tempfile(".population_publish_", tmpdir = directory, fileext = ".part")
  on.exit(unlink(temporary), add = TRUE)
  if (!file.copy(input_path, temporary, overwrite = FALSE) || file.size(temporary) != file.size(input_path) ||
      calculate_sha256(temporary) != expected_sha256 || !file.rename(temporary, destination)) {
    abort_population_reference(sprintf("Could not atomically publish raw population file: %s", destination))
  }
  invisible(destination)
}

#' Atomically publish a controlled CSV artifact.
publish_csv <- function(rows, path, label) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(paste0(".", label, "_"), tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(temporary), add = TRUE)
  tryCatch(readr::write_csv(rows, temporary, na = ""), error = function(error) abort_population_reference(error$message))
  if (!file.rename(temporary, path)) abort_population_reference(sprintf("Could not atomically publish %s.", label))
}

#' Acquire a lock directory atomically for the full C.14 execution.
acquire_population_lock <- function(path) {
  if (!dir.create(path, recursive = FALSE, showWarnings = FALSE)) {
    abort_population_reference(sprintf("Population-reference lock already exists: %s. Inspect it manually.", path))
  }
  writeLines(c(paste("pid", Sys.getpid()), paste("acquired_at_utc", format(Sys.time(), tz = "UTC", usetz = TRUE))), file.path(path, "diagnostic.txt"))
}

#' Report precise external-raw requirements without creating partial outputs.
report_external_requirements <- function(missing_sources, staging_directory) {
  details <- vapply(names(missing_sources), function(vintage) {
    source <- missing_sources[[vintage]]
    sprintf(
      paste0("- %s\n  title: %s\n  landing URL: %s\n  expected filename: %s\n  accepted format: %s\n  place original bytes at: %s"),
      vintage, source$source_title, source$source_landing_url, source$expected_filename,
      paste(source$accepted_formats, collapse = ", "), file.path(staging_directory, source$expected_filename)
    )
  }, character(1))
  abort_population_reference(paste(c("C.14 requires external_raw inputs; no partial artifacts were published.", details), collapse = "\n"))
}

#' Acquire or accept both official source files, validate, publish, and normalize them.
main <- function() {
  config <- read_project_config()
  sources <- read_population_sources(config)
  raw_directory <- configured_path(config, "directories", "population_raw")
  staging_directory <- configured_path(config, "directories", "population_staging")
  provenance_path <- configured_path(config, "artifacts", "population_source_provenance")
  denominator_path <- configured_path(config, "artifacts", "population_denominators")
  lock_path <- configured_path(config, "artifacts", "population_reference_lock")
  if (!startsWith(lock_path, configured_path(config, "directories", "metadata"))) abort_population_reference("Population-reference lock must be located in metadata.")
  dir.create(staging_directory, recursive = TRUE, showWarnings = FALSE)
  acquire_population_lock(lock_path)
  on.exit(unlink(lock_path, recursive = TRUE), add = TRUE)
  provenance <- read_population_provenance(provenance_path)
  prepared <- list()
  missing <- list()

  for (vintage in names(sources)) {
    source <- sources[[vintage]]
    existing <- reuse_existing_source(source, vintage, provenance, raw_directory)
    if (!is.null(existing)) {
      prepared[[vintage]] <- existing
      next
    }
    candidate <- tryCatch(download_online_source(source, staging_directory), error = function(error) NULL)
    if (is.null(candidate)) candidate <- find_external_source(source, staging_directory)
    if (is.null(candidate)) {
      missing[[vintage]] <- source
      next
    }
    initial_hash <- calculate_sha256(candidate$path)
    if (!file.size(candidate$path) || tools::file_ext(candidate$path) == "pdf") abort_population_reference(sprintf("Invalid staged file for %s.", vintage))
    normalized <- normalize_population_workbook(candidate$path, vintage, source, as.integer(unlist(config$population_reference$required_years[[vintage]], use.names = FALSE)))
    if (!identical(initial_hash, calculate_sha256(candidate$path))) abort_population_reference(sprintf("Staged bytes changed during validation for %s.", vintage))
    candidate$sha256 <- initial_hash
    candidate$normalized <- normalized
    candidate$existing <- FALSE
    prepared[[vintage]] <- candidate
  }
  if (length(missing)) report_external_requirements(missing, staging_directory)

  for (vintage in names(prepared)) {
    if (prepared[[vintage]]$existing) {
      prepared[[vintage]]$normalized <- normalize_population_workbook(prepared[[vintage]]$path, vintage, sources[[vintage]], as.integer(unlist(config$population_reference$required_years[[vintage]], use.names = FALSE)))
      next
    }
    source <- sources[[vintage]]
    destination <- file.path(raw_directory, source$expected_filename)
    prepared[[vintage]]$staging_path <- prepared[[vintage]]$path
    publish_raw_file(prepared[[vintage]]$path, destination, prepared[[vintage]]$sha256)
    prepared[[vintage]]$path <- destination
    prepared[[vintage]]$provenance <- tibble::tibble(
      population_provenance_schema_version = "1.0.0",
      source_resource_identifier = source$source_resource_identifier,
      projection_vintage = vintage,
      acquisition_mode = prepared[[vintage]]$acquisition_mode,
      origin_verification_status = prepared[[vintage]]$origin_verification_status,
      source_authority = source$source_authority,
      source_title = source$source_title,
      source_landing_url = source$source_landing_url,
      source_download_url = prepared[[vintage]]$source_download_url,
      source_format = tools::file_ext(source$expected_filename),
      source_sha256 = prepared[[vintage]]$sha256,
      source_publication_date = NA_character_,
      acquired_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
      local_filename = source$expected_filename
    )
  }
  provenance_rows <- dplyr::bind_rows(lapply(prepared, `[[`, "provenance")) |>
    dplyr::arrange(.data$projection_vintage)
  if (!identical(names(provenance_rows), population_provenance_columns) || nrow(provenance_rows) != length(sources)) abort_population_reference("Population provenance construction failed.")
  denominator_rows <- dplyr::bind_rows(lapply(prepared, `[[`, "normalized")) |>
    dplyr::arrange(.data$projection_vintage, .data$population_year, .data$geography_level, .data$province_reference_id)
  if (!identical(names(denominator_rows), population_denominator_columns) ||
      anyDuplicated(denominator_rows[c("projection_vintage", "population_year", "geography_level", "province_reference_id")])) abort_population_reference("Population denominator construction failed.")
  publish_csv(provenance_rows, provenance_path, "population_provenance")
  publish_csv(denominator_rows, denominator_path, "population_denominators")
  for (item in prepared) if (!item$existing && item$cleanup_after_run) unlink(item$staging_path)
  invisible(denominator_rows)
}

if (sys.nframe() == 0L) main()
