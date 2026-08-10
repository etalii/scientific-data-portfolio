###############################################################
# Argentina Dengue Analysis
#
# Script:
#   00_fetch_metadata.R
#
# Purpose:
#   Retrieve CKAN dataset metadata and build the versioned internal
#   resources_catalog contract.
#
# Inputs:
#   config/project.yml
#   CKAN package_show API response
#
# Outputs:
#   The resources catalog configured in artifacts.resources_catalog.
###############################################################

#' Stop execution with a clear, project-specific error message.
#'
#' @param message Error message to display.
#' @return This function does not return.
abort_pipeline <- function(message) {
  stop(message, call. = FALSE)
}

#' Read and validate the project configuration file.
#'
#' @param config_path Path to config/project.yml.
#' @return A validated project configuration list.
read_project_config <- function(config_path) {
  if (!file.exists(config_path)) {
    abort_pipeline(sprintf("Configuration file not found: %s", config_path))
  }

  config <- tryCatch(
    yaml::read_yaml(config_path),
    error = function(error) {
      abort_pipeline(
        sprintf("Could not read configuration file '%s': %s", config_path, error$message)
      )
    }
  )

  if (!is.list(config)) {
    abort_pipeline("Project configuration must be a YAML mapping.")
  }

  config
}

#' Return a required scalar string from a nested configuration section.
#'
#' @param config Project configuration list.
#' @param section Name of the first-level configuration section.
#' @param key Name of the required key within the section.
#' @return A non-empty scalar character string.
get_required_config_value <- function(config, section, key) {
  value <- config[[section]][[key]]

  if (
    is.null(value) ||
      length(value) != 1L ||
      is.na(value) ||
      !is.character(value) ||
      !nzchar(trimws(value))
  ) {
    abort_pipeline(
      sprintf("Missing or invalid configuration value: %s.%s", section, key)
    )
  }

  trimws(value)
}

#' Validate and extract the configuration needed for metadata acquisition.
#'
#' @param config Project configuration list.
#' @return A list containing acquisition-specific configuration values.
validate_acquisition_config <- function(config) {
  list(
    package_show_url = get_required_config_value(config, "api", "package_show_url"),
    dataset_id = get_required_config_value(config, "dataset", "id"),
    preferred_format = toupper(
      get_required_config_value(config, "dataset", "preferred_format")
    ),
    required_resource_state = tolower(
      get_required_config_value(config, "selection", "required_resource_state")
    ),
    catalog_path = get_required_config_value(config, "artifacts", "resources_catalog"),
    metadata_directory = get_required_config_value(config, "directories", "metadata")
  )
}

#' Retrieve the configured CKAN package metadata response.
#'
#' @param package_show_url Configured CKAN package_show endpoint.
#' @param dataset_id Configured CKAN dataset identifier.
#' @return A parsed CKAN response list.
fetch_ckan_package <- function(package_show_url, dataset_id) {
  request <- tryCatch(
    httr2::request(package_show_url) |>
      httr2::req_url_query(id = dataset_id) |>
      httr2::req_error(is_error = function(response) FALSE),
    error = function(error) {
      abort_pipeline(
        sprintf("Could not create CKAN request for dataset '%s': %s", dataset_id, error$message)
      )
    }
  )

  response <- tryCatch(
    httr2::req_perform(request),
    error = function(error) {
      abort_pipeline(
        sprintf("CKAN connection failed for dataset '%s': %s", dataset_id, error$message)
      )
    }
  )

  status_code <- httr2::resp_status(response)

  if (status_code < 200L || status_code >= 300L) {
    abort_pipeline(
      sprintf(
        "CKAN returned HTTP status %s for dataset '%s'.",
        status_code,
        dataset_id
      )
    )
  }

  tryCatch(
    httr2::resp_body_json(response, simplifyVector = FALSE),
    error = function(error) {
      abort_pipeline(
        sprintf("Could not parse CKAN JSON for dataset '%s': %s", dataset_id, error$message)
      )
    }
  )
}

#' Validate the CKAN response envelope and return its resource list.
#'
#' @param response Parsed CKAN response list.
#' @return A non-empty list of CKAN resource objects.
extract_ckan_resources <- function(response) {
  if (!is.list(response) || !identical(response$success, TRUE)) {
    abort_pipeline("CKAN response is incomplete or reports an unsuccessful request.")
  }

  if (!is.list(response$result) || !is.list(response$result$resources)) {
    abort_pipeline("CKAN response is missing result.resources.")
  }

  resources <- response$result$resources

  if (length(resources) == 0L) {
    abort_pipeline("CKAN response contains no resources for the configured dataset.")
  }

  resources
}

#' Convert an optional CKAN scalar field to a nullable character value.
#'
#' @param resource CKAN resource list.
#' @param field Name of the optional CKAN field.
#' @return A scalar character value or NA_character_.
get_optional_resource_field <- function(resource, field) {
  value <- resource[[field]]

  if (is.null(value) || length(value) == 0L) {
    return(NA_character_)
  }

  if (length(value) != 1L || !is.atomic(value)) {
    abort_pipeline(sprintf("CKAN resource field '%s' must be a scalar value.", field))
  }

  if (is.na(value)) {
    return(NA_character_)
  }

  value <- trimws(as.character(value))

  if (!nzchar(value)) {
    return(NA_character_)
  }

  value
}

#' Return a required non-empty scalar field from a CKAN resource.
#'
#' @param resource CKAN resource list.
#' @param field Name of the required CKAN field.
#' @param resource_index Position of the resource in the CKAN response.
#' @return A non-empty scalar character string.
get_required_resource_field <- function(resource, field, resource_index) {
  value <- get_optional_resource_field(resource, field)

  if (is.na(value)) {
    abort_pipeline(
      sprintf("CKAN resource %s is missing required field '%s'.", resource_index, field)
    )
  }

  value
}

#' Return a usable lowercase filename extension from a download URL.
#'
#' @param download_url Source download URL.
#' @return A lowercase extension or NA_character_ when no usable extension exists.
get_url_file_extension <- function(download_url) {
  url_path <- sub("[?#].*$", "", download_url)
  filename <- basename(url_path)
  extension <- tools::file_ext(filename)

  if (!nzchar(extension) || !grepl("^[[:alnum:]]+$", extension)) {
    return(NA_character_)
  }

  tolower(extension)
}

#' Generate a deterministic and filesystem-safe local filename.
#'
#' @param resource_id CKAN resource identifier.
#' @param download_url Source download URL.
#' @param resource_format Normalized resource format.
#' @return A filename derived from the resource identifier and format.
build_local_filename <- function(resource_id, download_url, resource_format) {
  if (!grepl("^[[:alnum:]][[:alnum:]._-]*$", resource_id)) {
    abort_pipeline(
      sprintf("CKAN resource_id '%s' is not safe for local filename generation.", resource_id)
    )
  }

  file_extension <- get_url_file_extension(download_url)

  if (!is.na(file_extension)) {
    return(sprintf("%s.%s", resource_id, file_extension))
  }

  format_suffix <- tolower(resource_format)
  format_suffix <- gsub("[^[:alnum:]]+", "_", format_suffix)
  format_suffix <- gsub("^_+|_+$", "", format_suffix)

  if (!nzchar(format_suffix)) {
    abort_pipeline(
      sprintf("CKAN resource '%s' has an unusable format for filename generation.", resource_id)
    )
  }

  sprintf("%s.%s", resource_id, format_suffix)
}

#' Determine whether a resource meets the configured download-eligibility policy.
#'
#' @param resource_format Normalized source resource format.
#' @param source_resource_state Nullable normalized source resource state.
#' @param config Acquisition-specific configuration values.
#' @return A list with eligible_for_download and eligibility_reason values.
determine_download_eligibility <- function(
  resource_format,
  source_resource_state,
  config
) {
  if (is.na(source_resource_state)) {
    return(
      list(
        eligible_for_download = FALSE,
        eligibility_reason = "ineligible_missing_source_state"
      )
    )
  }

  if (!identical(source_resource_state, config$required_resource_state)) {
    return(
      list(
        eligible_for_download = FALSE,
        eligibility_reason = "ineligible_non_active_source_state"
      )
    )
  }

  if (!identical(resource_format, config$preferred_format)) {
    return(
      list(
        eligible_for_download = FALSE,
        eligibility_reason = "ineligible_non_preferred_format"
      )
    )
  }

  list(
    eligible_for_download = TRUE,
    eligibility_reason = "eligible_preferred_format"
  )
}

#' Transform one CKAN resource into one resources_catalog contract row.
#'
#' @param resource CKAN resource list.
#' @param resource_index Position of the resource in the CKAN response.
#' @param config Acquisition-specific configuration values.
#' @return A one-row tibble matching the resources_catalog contract.
build_catalog_row <- function(resource, resource_index, config) {
  if (!is.list(resource)) {
    abort_pipeline(sprintf("CKAN resource %s is not an object.", resource_index))
  }

  resource_id <- get_required_resource_field(resource, "id", resource_index)
  resource_format <- toupper(
    get_required_resource_field(resource, "format", resource_index)
  )
  download_url <- get_required_resource_field(resource, "url", resource_index)

  if (!grepl("^[[:alpha:]][[:alnum:]+.-]*://", download_url)) {
    abort_pipeline(sprintf("CKAN resource '%s' has an invalid download URL.", resource_id))
  }

  source_resource_state <- get_optional_resource_field(resource, "state")

  if (!is.na(source_resource_state)) {
    source_resource_state <- tolower(source_resource_state)
  }

  eligibility <- determine_download_eligibility(
    resource_format = resource_format,
    source_resource_state = source_resource_state,
    config = config
  )

  tibble::tibble(
    resource_id = resource_id,
    resource_name = get_optional_resource_field(resource, "name"),
    resource_description = get_optional_resource_field(resource, "description"),
    resource_format = resource_format,
    download_url = download_url,
    local_filename = build_local_filename(resource_id, download_url, resource_format),
    source_created_at = get_optional_resource_field(resource, "created"),
    source_last_modified_at = get_optional_resource_field(resource, "last_modified"),
    source_resource_state = source_resource_state,
    eligible_for_download = eligibility$eligible_for_download,
    eligibility_reason = eligibility$eligibility_reason
  )
}

#' Build and validate the complete resources_catalog table.
#'
#' @param resources Non-empty list of CKAN resource objects.
#' @param config Acquisition-specific configuration values.
#' @return A sorted tibble matching resources_catalog contract version 1.0.0.
build_resources_catalog <- function(resources, config) {
  catalog <- purrr::map2_dfr(
    resources,
    seq_along(resources),
    build_catalog_row,
    config = config
  )

  if (anyDuplicated(catalog$resource_id)) {
    abort_pipeline("CKAN response contains duplicate resource_id values.")
  }

  dplyr::arrange(catalog, .data$resource_id)
}

#' Validate that the catalog output belongs to the configured metadata directory.
#'
#' @param catalog_path Configured catalog output path.
#' @param metadata_directory Configured metadata directory.
#' @return Invisibly returns the normalized catalog path when valid.
validate_catalog_output_path <- function(catalog_path, metadata_directory) {
  normalized_catalog_path <- normalizePath(
    catalog_path,
    winslash = "/",
    mustWork = FALSE
  )
  normalized_metadata_directory <- normalizePath(
    metadata_directory,
    winslash = "/",
    mustWork = FALSE
  )
  metadata_prefix <- paste0(normalized_metadata_directory, "/")

  if (
    identical(normalized_catalog_path, normalized_metadata_directory) ||
      !startsWith(normalized_catalog_path, metadata_prefix)
  ) {
    abort_pipeline(
      sprintf(
        "Catalog path must be inside configured metadata directory '%s': %s",
        metadata_directory,
        catalog_path
      )
    )
  }

  invisible(normalized_catalog_path)
}

#' Write the resources catalog without leaving a partial output on write failure.
#'
#' @param catalog Resources catalog tibble.
#' @param catalog_path Validated output path configured in project.yml.
#' @return Invisibly returns catalog_path when the write succeeds.
write_resources_catalog <- function(catalog, catalog_path) {
  catalog_directory <- dirname(catalog_path)

  if (!dir.exists(catalog_directory)) {
    directory_created <- tryCatch(
      dir.create(catalog_directory, recursive = TRUE, showWarnings = FALSE),
      warning = function(warning) FALSE,
      error = function(error) FALSE
    )

    if (!isTRUE(directory_created) && !dir.exists(catalog_directory)) {
      abort_pipeline(
        sprintf("Could not create catalog directory: %s", catalog_directory)
      )
    }
  }

  temporary_path <- tempfile(
    pattern = ".resources_catalog_",
    tmpdir = catalog_directory,
    fileext = ".csv"
  )

  on.exit(unlink(temporary_path), add = TRUE)

  tryCatch(
    readr::write_csv(catalog, temporary_path, na = ""),
    error = function(error) {
      abort_pipeline(
        sprintf("Could not write temporary resources catalog: %s", error$message)
      )
    }
  )

  if (!file.rename(temporary_path, catalog_path)) {
    abort_pipeline(
      sprintf("Could not replace resources catalog at: %s", catalog_path)
    )
  }

  invisible(catalog_path)
}

#' Execute metadata acquisition and catalog generation.
#'
#' @return Invisibly returns the configured catalog path on success.
main <- function() {
  config_path <- "config/project.yml"
  config <- read_project_config(config_path)
  acquisition_config <- validate_acquisition_config(config)
  ckan_response <- fetch_ckan_package(
    package_show_url = acquisition_config$package_show_url,
    dataset_id = acquisition_config$dataset_id
  )
  resources <- extract_ckan_resources(ckan_response)
  catalog <- build_resources_catalog(resources, acquisition_config)
  validate_catalog_output_path(
    catalog_path = acquisition_config$catalog_path,
    metadata_directory = acquisition_config$metadata_directory
  )
  catalog_path <- write_resources_catalog(catalog, acquisition_config$catalog_path)

  message(sprintf("Resources catalog written to: %s", catalog_path))

  invisible(catalog_path)
}

#' Determine whether this acquisition entry point is executed directly by Rscript.
#'
#' @return TRUE only when this file is the Rscript input file.
is_direct_script_execution <- function() {
  command_arguments <- commandArgs(trailingOnly = FALSE)
  file_arguments <- command_arguments[startsWith(command_arguments, "--file=")]

  if (length(file_arguments) != 1L) {
    return(FALSE)
  }

  identical(
    basename(sub("^--file=", "", file_arguments)),
    "00_fetch_metadata.R"
  )
}

if (is_direct_script_execution()) {
  main()
}
