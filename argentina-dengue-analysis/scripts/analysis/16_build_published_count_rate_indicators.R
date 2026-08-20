###############################################################
# Argentina Dengue Analysis
# Script: 16_build_published_count_rate_indicators.R
# Purpose: Publish descriptive rates from C.12 counts, C.14 denominators,
#          and C.15 validated geographic mappings.
###############################################################

abort_rate <- function(message) stop(message, call. = FALSE)

read_config <- function() yaml::read_yaml("config/project.yml")

read_csv_contract <- function(path, required_columns) {
  data <- readr::read_csv(path, show_col_types = FALSE)
  if (!identical(names(data), required_columns) || nrow(readr::problems(data)) > 0L) {
    abort_rate(sprintf("Input does not satisfy its expected schema: %s", path))
  }
  data
}

publish_csv_atomically <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary_path <- tempfile(".c16_", dirname(path), ".tmp")
  on.exit(unlink(temporary_path), add = TRUE)
  readr::write_csv(data, temporary_path, na = "")
  if (!file.rename(temporary_path, path)) abort_rate(sprintf("Could not publish: %s", path))
}

published_count_rate <- function(case_count, population) 100000 * case_count / population

rate_period_basis <- function(weeks) {
  if (identical(sort(unique(weeks)), 1:52)) "observed_weeks_01_52" else "observed_week_subset"
}

observed_week_set <- function(weeks) paste(sprintf("W%02d", sort(unique(weeks))), collapse = "|")

indicator_metadata <- function(scope, scenario, vintage, reference_date, basis, rows) {
  tibble::tibble(
    epidemiological_indicator_schema_version = rep("1.0.0", rows),
    analysis_scope_id = rep(scope$analysis_scope_id[[1]], rows),
    source_year = rep(scope$source_year[[1]], rows),
    source_resource_id = rep(scope$source_resource_id[[1]], rows),
    denominator_scenario = rep(scenario, rows),
    projection_vintage = rep(vintage, rows),
    population_reference_date = rep(reference_date, rows),
    rate_period_basis = rep(basis, rows)
  )
}

add_indicator_metadata <- function(data, scope, scenario, vintage, reference_date, basis) {
  dplyr::bind_cols(indicator_metadata(scope, scenario, vintage, reference_date, basis, nrow(data)), data)
}

validate_outputs <- function(outputs, scenarios) {
  if (nrow(outputs$national_summary) != 8L || nrow(outputs$weekly_national) != 316L) {
    abort_rate("Unexpected national output cardinality.")
  }
  for (name in names(outputs)) {
    data <- outputs[[name]]
    grain <- c("analysis_scope_id", "denominator_scenario", intersect("source_week", names(data)),
               intersect("reference_province_id", names(data)), intersect("epidemiological_region", names(data)))
    if (anyDuplicated(data[grain]) > 0L) abort_rate(sprintf("Duplicate output grain: %s", name))
    if (any(!is.finite(data$published_count_rate_100k)) || any(data$published_count_rate_100k < 0)) {
      abort_rate(sprintf("Invalid published-count rate: %s", name))
    }
  }
  national_from_weekly <- outputs$weekly_national |>
    dplyr::group_by(analysis_scope_id, denominator_scenario) |>
    dplyr::summarise(published_row_count = sum(published_row_count),
                     published_case_count = sum(published_case_count), .groups = "drop")
  checked <- dplyr::left_join(outputs$national_summary, national_from_weekly,
                              by = c("analysis_scope_id", "denominator_scenario"),
                              suffix = c("", "_weekly"))
  if (any(checked$published_row_count != checked$published_row_count_weekly) ||
      any(checked$published_case_count != checked$published_case_count_weekly)) {
    abort_rate("National summary does not reconcile to C.12 weekly national counts.")
  }
  for (name in c("province_summary", "region_summary")) {
    data <- outputs[[name]]
    if (any(!is.finite(data$published_case_share_of_national)) ||
        any(data$published_case_share_of_national < 0) ||
        any(data$published_case_share_of_national > 1)) {
      abort_rate(sprintf("Invalid national case share: %s", name))
    }
    territorial_totals <- data |>
      dplyr::group_by(analysis_scope_id, denominator_scenario) |>
      dplyr::summarise(published_case_count = sum(published_case_count), .groups = "drop") |>
      dplyr::left_join(outputs$national_summary[c("analysis_scope_id", "denominator_scenario", "published_case_count")],
                       by = c("analysis_scope_id", "denominator_scenario"), suffix = c("_territorial", "_national"))
    if (any(territorial_totals$published_case_count_territorial >
            territorial_totals$published_case_count_national)) {
      abort_rate(sprintf("Territorial count exceeds national count: %s", name))
    }
  }
  scenarios_found <- sort(unique(outputs$national_summary$denominator_scenario))
  if (!identical(scenarios_found, sort(scenarios))) abort_rate("Missing denominator scenario.")
}

#' Build and publish all C.16 published-count rate indicators.
main <- function() {
  config <- read_config()
  artifacts <- config$artifacts
  weekly_national_columns <- c("multiyear_analysis_table_schema_version", "analysis_scope_id", "source_resource_id", "source_year", "source_week", "published_row_count", "published_case_count")
  province_summary_columns <- c("multiyear_analysis_table_schema_version", "analysis_scope_id", "source_resource_id", "source_year", "province_id", "province_name", "published_row_count", "published_case_count", "published_case_share")
  province_weekly_columns <- c("multiyear_analysis_table_schema_version", "analysis_scope_id", "source_resource_id", "source_year", "source_week", "province_id", "province_name", "published_row_count", "published_case_count")
  population_columns <- c("population_schema_version", "source_resource_identifier", "geography_level", "population_year", "province_reference_id", "province_reference_name", "population", "population_scope", "projection_vintage", "census_basis", "reference_date")
  source_crosswalk_columns <- c("source_geography_crosswalk_schema_version", "source_schema_family", "source_province_id", "source_province_name", "reference_province_id", "reference_province_name", "mapping_status", "mapping_basis", "source_geography_semantics_status")
  region_crosswalk_columns <- c("region_crosswalk_schema_version", "reference_province_id", "reference_province_name", "epidemiological_region", "source_authority", "source_document", "source_url", "effective_context")
  mapping_snapshot_columns <- c("geographic_validation_schema_version", "analysis_scope_id", "source_year", "source_resource_id", "source_schema_family", "total_published_row_count", "total_published_case_count", "mapped_published_row_count", "mapped_published_case_count", "name_based_unverified_published_row_count", "name_based_unverified_published_case_count", "ambiguous_published_row_count", "ambiguous_published_case_count", "unmapped_published_row_count", "unmapped_published_case_count", "unknown_published_row_count", "unknown_published_case_count", "geographic_mapping_completeness", "source_geography_semantics_status", "rate_geography_eligibility_status", "rate_geography_reason_codes")

  c12_weekly_national <- read_csv_contract(artifacts$multiyear_dengue_weekly_national, weekly_national_columns)
  c12_province_summary <- read_csv_contract(artifacts$multiyear_dengue_province_summary, province_summary_columns)
  c12_province_weekly <- read_csv_contract(artifacts$multiyear_dengue_weekly_province, province_weekly_columns)
  denominators <- read_csv_contract(artifacts$population_denominators, population_columns)
  source_crosswalk <- read_csv_contract(artifacts$source_geography_crosswalk, source_crosswalk_columns)
  region_crosswalk <- read_csv_contract(artifacts$province_region_crosswalk, region_crosswalk_columns)
  mapping_snapshot <- read_csv_contract(artifacts$geographic_mapping_validation_snapshot, mapping_snapshot_columns)

  scenarios <- config$published_count_rate$scenarios
  output <- list(national_summary = list(), weekly_national = list(), province_summary = list(),
                 weekly_province = list(), region_summary = list(), weekly_region = list())
  scopes <- dplyr::distinct(c12_weekly_national, analysis_scope_id, source_year, source_resource_id)

  for (scope_index in seq_len(nrow(scopes))) {
    scope <- scopes[scope_index, ]
    scope_weekly_national <- dplyr::filter(c12_weekly_national, analysis_scope_id == scope$analysis_scope_id)
    snapshot <- dplyr::filter(mapping_snapshot, analysis_scope_id == scope$analysis_scope_id)
    if (nrow(snapshot) != 1L) abort_rate("Expected exactly one C.15 snapshot row per scope.")
    basis <- rate_period_basis(scope_weekly_national$source_week)
    national_total <- dplyr::summarise(scope_weekly_national,
      published_row_count = sum(published_row_count), published_case_count = sum(published_case_count))
    week_count <- dplyr::n_distinct(scope_weekly_national$source_week)
    week_set <- observed_week_set(scope_weekly_national$source_week)

    for (scenario in names(scenarios)) {
      vintage <- scenarios[[scenario]][[as.character(scope$source_year[[1]])]]
      if (is.null(vintage)) abort_rate("Missing configured denominator vintage.")
      national_denominator <- dplyr::filter(denominators, geography_level == "national",
        population_year == scope$source_year, projection_vintage == vintage)
      if (nrow(national_denominator) != 1L || national_denominator$population[[1]] <= 0) {
        abort_rate("Expected one positive national denominator.")
      }
      ref_date <- national_denominator$reference_date[[1]]

      national_summary_data <- dplyr::mutate(national_total,
        national_population = national_denominator$population[[1]],
        published_count_rate_100k = published_count_rate(published_case_count, national_population),
        observed_week_count = week_count, observed_week_set = week_set)
      output$national_summary[[length(output$national_summary) + 1L]] <- add_indicator_metadata(
        national_summary_data, scope, scenario, vintage, ref_date, basis)

      national_weekly_data <- dplyr::transmute(scope_weekly_national, source_week,
        published_row_count, published_case_count, national_population = national_denominator$population[[1]],
        published_count_rate_100k = published_count_rate(published_case_count, national_population))
      output$weekly_national[[length(output$weekly_national) + 1L]] <- add_indicator_metadata(
        national_weekly_data, scope, scenario, vintage, ref_date, basis)

      if (!identical(snapshot$rate_geography_eligibility_status[[1]], "supported_with_caveats")) next
      valid_mappings <- dplyr::filter(source_crosswalk,
        source_schema_family == snapshot$source_schema_family[[1]],
        mapping_status %in% c("documented_exact", "validated_exact"))
      province_denominators <- dplyr::filter(denominators, geography_level == "province",
        population_year == scope$source_year, projection_vintage == vintage)
      regional_denominators <- region_crosswalk |>
        dplyr::left_join(
          province_denominators[c("province_reference_id", "population")],
          by = c("reference_province_id" = "province_reference_id")
        ) |>
        dplyr::group_by(epidemiological_region) |>
        dplyr::summarise(regional_population = sum(population), .groups = "drop")
      if (any(!is.finite(regional_denominators$regional_population)) ||
          any(regional_denominators$regional_population <= 0)) {
        abort_rate("Could not derive a positive BEN regional denominator.")
      }

      mapped_summary <- c12_province_summary |>
        dplyr::filter(analysis_scope_id == scope$analysis_scope_id) |>
        dplyr::left_join(valid_mappings, by = c("province_id" = "source_province_id", "province_name" = "source_province_name")) |>
        dplyr::filter(!is.na(reference_province_id)) |>
        dplyr::group_by(reference_province_id, reference_province_name) |>
        dplyr::summarise(published_row_count = sum(published_row_count),
                         published_case_count = sum(published_case_count), .groups = "drop") |>
        dplyr::left_join(province_denominators[c("province_reference_id", "population")],
                         by = c("reference_province_id" = "province_reference_id"))
      if (any(is.na(mapped_summary$population)) || any(mapped_summary$population <= 0)) {
        abort_rate("Missing positive province denominator.")
      }
      if (sum(mapped_summary$published_row_count) != snapshot$mapped_published_row_count[[1]] ||
          sum(mapped_summary$published_case_count) != snapshot$mapped_published_case_count[[1]]) {
        abort_rate("Mapped provincial C.12 counts do not reconcile to C.15.")
      }
      province_summary_data <- dplyr::transmute(mapped_summary, reference_province_id, reference_province_name,
        published_row_count, published_case_count,
        published_case_share_of_national = published_case_count / national_total$published_case_count[[1]],
        province_population = population, published_count_rate_100k = published_count_rate(published_case_count, province_population),
        geographic_mapping_completeness = snapshot$geographic_mapping_completeness[[1]])
      output$province_summary[[length(output$province_summary) + 1L]] <- add_indicator_metadata(
        province_summary_data, scope, scenario, vintage, ref_date, basis)

      mapped_weekly <- c12_province_weekly |>
        dplyr::filter(analysis_scope_id == scope$analysis_scope_id) |>
        dplyr::left_join(valid_mappings, by = c("province_id" = "source_province_id", "province_name" = "source_province_name")) |>
        dplyr::filter(!is.na(reference_province_id)) |>
        dplyr::group_by(source_week, reference_province_id, reference_province_name) |>
        dplyr::summarise(published_row_count = sum(published_row_count),
                         published_case_count = sum(published_case_count), .groups = "drop") |>
        dplyr::left_join(province_denominators[c("province_reference_id", "population")],
                         by = c("reference_province_id" = "province_reference_id"))
      if (any(is.na(mapped_weekly$population)) || any(mapped_weekly$population <= 0)) {
        abort_rate("Missing positive weekly province denominator.")
      }
      weekly_summary <- mapped_weekly |>
        dplyr::group_by(reference_province_id) |>
        dplyr::summarise(published_row_count = sum(published_row_count),
                         published_case_count = sum(published_case_count), .groups = "drop")
      reconciliation <- dplyr::left_join(mapped_summary[c("reference_province_id", "published_row_count", "published_case_count")],
        weekly_summary, by = "reference_province_id", suffix = c("_summary", "_weekly"))
      if (any(reconciliation$published_row_count_summary != reconciliation$published_row_count_weekly) ||
          any(reconciliation$published_case_count_summary != reconciliation$published_case_count_weekly)) {
        abort_rate("Mapped weekly provincial counts do not reconcile to C.12 provincial summary.")
      }
      province_weekly_data <- dplyr::transmute(mapped_weekly, source_week, reference_province_id,
        reference_province_name, published_row_count, published_case_count, province_population = population,
        published_count_rate_100k = published_count_rate(published_case_count, province_population))
      output$weekly_province[[length(output$weekly_province) + 1L]] <- add_indicator_metadata(
        province_weekly_data, scope, scenario, vintage, ref_date, basis)

      region_summary_data <- province_summary_data |>
        dplyr::left_join(region_crosswalk[c("reference_province_id", "epidemiological_region")], by = "reference_province_id") |>
        dplyr::group_by(epidemiological_region) |>
        dplyr::summarise(published_row_count = sum(published_row_count),
          published_case_count = sum(published_case_count),
          geographic_mapping_completeness = dplyr::first(geographic_mapping_completeness), .groups = "drop") |>
        dplyr::left_join(regional_denominators, by = "epidemiological_region") |>
        dplyr::mutate(published_case_share_of_national = published_case_count / national_total$published_case_count[[1]],
          published_count_rate_100k = published_count_rate(published_case_count, regional_population))
      if (any(is.na(region_summary_data$epidemiological_region))) abort_rate("Mapped province lacks BEN region.")
      if (sum(region_summary_data$published_row_count) != sum(province_summary_data$published_row_count) ||
          sum(region_summary_data$published_case_count) != sum(province_summary_data$published_case_count)) {
        abort_rate("Regional summary does not reconcile to mapped province summary.")
      }
      output$region_summary[[length(output$region_summary) + 1L]] <- add_indicator_metadata(
        region_summary_data, scope, scenario, vintage, ref_date, basis)

      region_weekly_data <- province_weekly_data |>
        dplyr::left_join(region_crosswalk[c("reference_province_id", "epidemiological_region")], by = "reference_province_id") |>
        dplyr::group_by(source_week, epidemiological_region) |>
        dplyr::summarise(published_row_count = sum(published_row_count),
          published_case_count = sum(published_case_count), .groups = "drop") |>
        dplyr::left_join(regional_denominators, by = "epidemiological_region") |>
        dplyr::mutate(published_count_rate_100k = published_count_rate(published_case_count, regional_population))
      if (any(is.na(region_weekly_data$epidemiological_region))) abort_rate("Mapped weekly province lacks BEN region.")
      output$weekly_region[[length(output$weekly_region) + 1L]] <- add_indicator_metadata(
        region_weekly_data, scope, scenario, vintage, ref_date, basis)
    }
  }

  output <- lapply(output, dplyr::bind_rows)
  output$national_summary <- dplyr::arrange(output$national_summary, source_year, denominator_scenario)
  output$weekly_national <- dplyr::arrange(output$weekly_national, source_year, denominator_scenario, source_week)
  output$province_summary <- dplyr::arrange(output$province_summary, source_year, denominator_scenario, reference_province_id)
  output$weekly_province <- dplyr::arrange(output$weekly_province, source_year, denominator_scenario, source_week, reference_province_id)
  region_order <- config$published_count_rate$ben_region_order
  output$region_summary <- dplyr::arrange(output$region_summary, source_year, denominator_scenario, match(epidemiological_region, region_order))
  output$weekly_region <- dplyr::arrange(output$weekly_region, source_year, denominator_scenario, source_week, match(epidemiological_region, region_order))
  validate_outputs(output, names(scenarios))

  paths <- c(national_summary = artifacts$epidemiology_national_summary,
    weekly_national = artifacts$epidemiology_weekly_national,
    province_summary = artifacts$epidemiology_province_summary,
    weekly_province = artifacts$epidemiology_weekly_province,
    region_summary = artifacts$epidemiology_region_summary,
    weekly_region = artifacts$epidemiology_weekly_region)
  for (name in names(output)) publish_csv_atomically(output[[name]], paths[[name]])
  invisible(output)
}

if (sys.nframe() == 0L) main()
