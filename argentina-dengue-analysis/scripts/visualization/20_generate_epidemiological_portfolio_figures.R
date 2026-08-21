###############################################################
# Argentina Dengue Analysis
# Script: 20_generate_epidemiological_portfolio_figures.R
# Purpose: Render the four C.20 epidemiological portfolio figures.
###############################################################

figure_dimensions <- list(
  season_national_temporal_profile = c(width = 2400L, height = 1600L),
  season_regional_observed_timing = c(width = 2400L, height = 1800L),
  province_count_rate_rank_shift_2024 = c(width = 2400L, height = 1800L),
  region_population_adjusted_burden_2024 = c(width = 2400L, height = 1350L)
)

abort_c20 <- function(message) stop(message, call. = FALSE)

#' Read the project configuration from its bootstrap path.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) abort_c20("Configuration file not found: config/project.yml")
  tryCatch(yaml::read_yaml("config/project.yml"), error = function(error) abort_c20(error$message))
}

#' Require one non-empty scalar configuration string.
required_string <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (is.null(value) || length(value) != 1L || !is.character(value) || is.na(value) || !nzchar(trimws(value))) abort_c20(sprintf("Missing configuration value: %s.%s", section, key))
  trimws(value)
}

#' Check that a configured path is project-relative and inside its directory.
validate_output_path <- function(path, directory, label) {
  if (grepl("^(/|[[:alpha:]]:[/\\\\])", path)) abort_c20(sprintf("%s must be project-relative.", label))
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidate <- normalizePath(file.path(root, path), winslash = "/", mustWork = FALSE)
  parent <- normalizePath(file.path(root, directory), winslash = "/", mustWork = FALSE)
  if (!startsWith(candidate, paste0(parent, "/"))) abort_c20(sprintf("%s must be inside %s.", label, directory))
}

#' Read one CSV with an exact expected schema and no parsing problems.
read_contract_csv <- function(path, expected_columns, label) {
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) abort_c20(sprintf("Missing input: %s", label))
  table <- tryCatch(readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()), show_col_types = FALSE), error = function(error) abort_c20(sprintf("Could not read %s: %s", label, error$message)))
  if (!identical(names(table), expected_columns) || nrow(readr::problems(table)) || !nrow(table)) abort_c20(sprintf("Invalid schema or CSV syntax: %s", label))
  table
}

#' Strictly parse a finite numeric contract field.
parse_number <- function(values, label, minimum = -Inf) {
  parsed <- suppressWarnings(as.numeric(values))
  if (any(is.na(parsed) | !is.finite(parsed) | parsed < minimum)) abort_c20(sprintf("Invalid numeric field: %s", label))
  parsed
}

#' Strictly parse a non-negative whole-number contract field.
parse_count <- function(values, label) {
  parsed <- parse_number(values, label, minimum = 0)
  if (any(parsed != floor(parsed))) abort_c20(sprintf("Non-integer count field: %s", label))
  parsed
}

#' Strictly parse an optional non-negative whole-number contract field.
parse_optional_count <- function(values, label) {
  parsed <- suppressWarnings(as.numeric(values))
  if (any(!is.na(parsed) & (!is.finite(parsed) | parsed < 0 | parsed != floor(parsed)))) abort_c20(sprintf("Invalid optional count field: %s", label))
  parsed
}

#' Require a unique logical key.
require_unique_key <- function(table, columns, label) {
  if (anyDuplicated(table[columns])) abort_c20(sprintf("Duplicate key in %s.", label))
}

#' Format values for localized figure labels.
format_number <- function(values, digits = 0L, language = "es") {
  separators <- if (identical(language, "en")) list(big = ",", decimal = ".") else list(big = ".", decimal = ",")
  format(round(values, digits), big.mark = separators$big, decimal.mark = separators$decimal, trim = TRUE, scientific = FALSE, nsmall = digits)
}

#' Return visible text for one supported C.20 localization.
localized_strings <- function(language) {
  if (identical(language, "en")) return(list(
    season_title = "Published burden by season week", season_scope = "Season", published_counts = "published counts", mapping_completeness = "geographic mapping completeness", season_week = "Season week", observed_peak = "Observed peak", weighted_center = "Weighted center", weighted_median = "Weighted median", weeks = "weeks", regional_title = "Observed regional timing of published burden", tied_subtitle = "tied peaks are shown without selecting an arbitrary week", peak_tie = "Observed peaks (tie)", observed_weeks = "observed weeks", provinces_at_peak = "provinces at peak", tied_peak = "tied peak", regional_caption = "Observed region weeks only; missing region-week rows are not treated as zero.\nTerritorial numerators do not redistribute nonassignable geography.", rank_title = "Population adjustment changes the territorial ordering", calendar_year = "Calendar year", denominator_scenario = "denominator scenario", count_rank = "Published count rank", rate_rank = "Published-count rate per 100,000 rank", rank_axis = "Rank (1 = highest value)", rate_caption = "Published-count rate per 100,000; it is not incidence, risk, or unique persons.\nTerritorial numerators exclude unknown/nonassignable geography; no redistribution was applied.", region_title = "Published burden and population-adjusted rate by BEN region", counts = "Published counts", rate = "Published-count rate\nper 100,000", region_caption = "Published-count rate per 100,000; it is not incidence. Territorial numerators include only geographically mapped published counts;\nunknown/nonassignable geography was not redistributed.", national_caption = "National totals retain unknown/nonassignable geography. Geographic mapping completeness measures geographic assignment, not surveillance completeness."))
  list(
    season_title = "Carga publicada por semana estacional", season_scope = "Temporada", published_counts = "conteos publicados", mapping_completeness = "completitud de asignación geográfica", season_week = "Semana estacional", observed_peak = "Pico observado", weighted_center = "Centro ponderado", weighted_median = "Mediana ponderada", weeks = "semanas", regional_title = "Timing regional observado de la carga publicada", tied_subtitle = "los empates se muestran sin seleccionar una semana arbitraria", peak_tie = "Picos observados (empate)", observed_weeks = "semanas observadas", provinces_at_peak = "provincias en pico", tied_peak = "pico con empate", regional_caption = "Solo semanas regionales observadas: las filas regional-semana ausentes no se tratan como cero.\nLos conteos territoriales no redistribuyen geografía no asignable.", rank_title = "El ajuste por población cambia el orden territorial", calendar_year = "Año calendario", denominator_scenario = "escenario de denominador", count_rank = "Rango por\nconteos publicados", rate_rank = "Rango por tasa de conteos\npublicados por 100.000", rank_axis = "Rango (1 = mayor valor)", rate_caption = "Tasa de conteos publicados por 100.000; no es incidencia, riesgo ni personas únicas.\nLos numeradores territoriales excluyen geografía unknown/nonassignable; no se redistribuyó.", region_title = "Carga publicada y tasa poblacional por región BEN", counts = "Conteos publicados", rate = "Tasa de conteos publicados\npor 100.000", region_caption = "Tasa de conteos publicados por 100.000; no es incidencia. Los numeradores territoriales incluyen solo geografía mapeada;\nla geografía unknown/nonassignable no se redistribuyó.", national_caption = "El total nacional conserva geografía unknown/nonassignable. La completitud territorial mide asignación geográfica, no completitud de vigilancia.")
}

#' Construct the C.20 visual theme.
portfolio_theme <- function() {
  ggplot2::theme_minimal(base_size = 20, base_family = "sans") +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", colour = "#173042", margin = ggplot2::margin(b = 8)),
      plot.subtitle = ggplot2::element_text(colour = "#405364", margin = ggplot2::margin(b = 14)),
      plot.caption = ggplot2::element_text(colour = "#405364", hjust = 0, margin = ggplot2::margin(t = 14)),
      axis.title = ggplot2::element_text(face = "bold", colour = "#173042"),
      axis.text = ggplot2::element_text(colour = "#405364"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "#D9E1E6", linewidth = 0.35),
      strip.text = ggplot2::element_text(face = "bold", colour = "#173042"),
      strip.background = ggplot2::element_rect(fill = "#EEF3F6", colour = NA),
      plot.margin = ggplot2::margin(24, 48, 40, 28)
    )
}

#' Return the controlled C.20 configuration and output paths.
visualization_settings <- function(config, language) {
  figures_directory <- required_string(config, "directories", "figures")
  figure_ids <- names(figure_dimensions)
  output_keys <- paste0(figure_ids, if (identical(language, "en")) "_en_figure" else "_figure")
  outputs <- purrr::set_names(purrr::map_chr(output_keys, ~ required_string(config, "artifacts", .x)), figure_ids)
  purrr::iwalk(outputs, ~ validate_output_path(.x, figures_directory, .y))
  if (anyDuplicated(unname(outputs))) abort_c20("C.20 figure outputs must be distinct.")
  policy <- config$epidemiological_portfolio_visualization
  if (is.null(policy) || !is.list(policy)) abort_c20("Missing epidemiological_portfolio_visualization configuration.")
  if (!language %in% policy$supported_languages) abort_c20(sprintf("Unsupported C.20 language: %s", language))
  if (is.null(policy$calendar_year) || length(policy$calendar_year) != 1L || policy$calendar_year != floor(policy$calendar_year)) abort_c20("Invalid C.20 calendar year.")
  list(
    figures_directory = figures_directory,
    language = language,
    outputs = outputs,
    dpi = as.integer(config$visualization$png_resolution_dpi),
    season_scope_id = config$epidemiological_season$scope_id,
    season_label = config$epidemiological_season$season_label,
    calendar_scope_id = policy$calendar_year_scope_id,
    calendar_year = as.integer(policy$calendar_year),
    scenario = policy$rate_denominator_scenario,
    featured_provinces = policy$featured_provinces,
    regional_expectations = policy$regional_rank_expectations,
    ben_region_order = config$published_count_rate$ben_region_order,
    paths = list(
      season_weekly_national = required_string(config, "artifacts", "season_weekly_national"),
      season_national_summary = required_string(config, "artifacts", "season_national_summary"),
      season_temporal_national_summary = required_string(config, "artifacts", "season_temporal_national_summary"),
      season_temporal_region_summary = required_string(config, "artifacts", "season_temporal_region_summary"),
      season_temporal_windows = required_string(config, "artifacts", "season_temporal_national_concentration_windows"),
      epidemiology_national_summary = required_string(config, "artifacts", "epidemiology_national_summary"),
      epidemiology_province_summary = required_string(config, "artifacts", "epidemiology_province_summary"),
      epidemiology_region_summary = required_string(config, "artifacts", "epidemiology_region_summary")
    )
  )
}

#' Read and validate all material C.16, C.18, and C.19 inputs.
read_and_validate_inputs <- function(settings) {
  weekly_columns <- c("season_indicator_schema_version", "season_scope_id", "season_label", "season_week_index", "source_year", "source_week", "denominator_scenario", "projection_vintage", "population_reference_date", "published_row_count", "published_case_count", "mapped_published_case_count", "unknown_published_case_count", "nonassignable_published_case_count", "geographic_mapping_completeness", "national_population", "published_count_rate_100k")
  season_summary_columns <- c("season_indicator_schema_version", "season_scope_id", "season_label", "season_published_row_count", "season_published_case_count", "season_week_count", "season_geographic_mapping_completeness", "season_unknown_published_case_count", "season_unknown_published_case_share", "cumulative_rate_status")
  national_temporal_columns <- c("season_temporal_descriptor_schema_version", "season_scope_id", "season_label", "national_temporal_coverage_basis", "national_published_row_count", "national_published_case_count", "national_observed_week_count", "peak_count_value", "peak_count_selection_status", "peak_count_tie_count", "peak_count_tied_season_week_indices", "peak_count_season_week_index", "peak_count_source_year", "peak_count_source_week", "peak_rate_value", "peak_rate_selection_status", "peak_rate_tie_count", "peak_rate_tied_season_week_indices", "peak_rate_season_week_index", "peak_rate_source_year", "peak_rate_source_week", "count_rate_peak_alignment_status", "rate_peak_sensitivity_status", "published_count_weighted_season_week", "published_count_weighted_median_season_week", "published_count_weighted_median_source_year", "published_count_weighted_median_source_week", "peak_unknown_published_case_count", "unknown_peak_selection_status", "unknown_peak_tie_count", "unknown_peak_tied_season_week_indices", "unknown_peak_season_week_index", "unknown_peak_source_year", "unknown_peak_source_week", "peak_unknown_published_case_share", "unknown_share_peak_selection_status", "geographic_mapping_completeness_at_national_count_peak")
  regional_temporal_columns <- c("season_temporal_descriptor_schema_version", "season_scope_id", "season_label", "epidemiological_region", "regional_temporal_coverage_basis", "regional_published_row_count", "regional_published_case_count", "regional_observed_week_count", "peak_count_value", "peak_count_selection_status", "peak_count_tie_count", "peak_count_tied_season_week_indices", "peak_count_season_week_index", "peak_count_source_year", "peak_count_source_week", "peak_rate_value", "peak_rate_selection_status", "peak_rate_tie_count", "peak_rate_tied_season_week_indices", "peak_rate_season_week_index", "peak_rate_source_year", "peak_rate_source_week", "count_rate_peak_alignment_status", "rate_peak_sensitivity_status", "peak_count_lag_vs_national", "published_count_weighted_season_week", "published_count_weighted_median_season_week", "published_count_weighted_median_source_year", "published_count_weighted_median_source_week", "peak_region_observed_province_count", "peak_region_total_province_count", "peak_region_observed_province_fraction")
  window_columns <- c("season_temporal_window_schema_version", "season_scope_id", "season_label", "target_share", "window_start_season_week_index", "window_end_season_week_index", "window_length_weeks", "window_published_case_count", "window_published_case_share", "start_source_year", "start_source_week", "end_source_year", "end_source_week")
  national_rate_columns <- c("epidemiological_indicator_schema_version", "analysis_scope_id", "source_year", "source_resource_id", "denominator_scenario", "projection_vintage", "population_reference_date", "rate_period_basis", "published_row_count", "published_case_count", "national_population", "published_count_rate_100k", "observed_week_count", "observed_week_set")
  province_rate_columns <- c("epidemiological_indicator_schema_version", "analysis_scope_id", "source_year", "source_resource_id", "denominator_scenario", "projection_vintage", "population_reference_date", "rate_period_basis", "reference_province_id", "reference_province_name", "published_row_count", "published_case_count", "published_case_share_of_national", "province_population", "published_count_rate_100k", "geographic_mapping_completeness")
  region_rate_columns <- c("epidemiological_indicator_schema_version", "analysis_scope_id", "source_year", "source_resource_id", "denominator_scenario", "projection_vintage", "population_reference_date", "rate_period_basis", "epidemiological_region", "published_row_count", "published_case_count", "geographic_mapping_completeness", "regional_population", "published_case_share_of_national", "published_count_rate_100k")
  weekly <- read_contract_csv(settings$paths$season_weekly_national, weekly_columns, "C.18 weekly national")
  season_summary <- read_contract_csv(settings$paths$season_national_summary, season_summary_columns, "C.18 national summary")
  national_temporal <- read_contract_csv(settings$paths$season_temporal_national_summary, national_temporal_columns, "C.19 national temporal summary")
  regional_temporal <- read_contract_csv(settings$paths$season_temporal_region_summary, regional_temporal_columns, "C.19 regional temporal summary")
  windows <- read_contract_csv(settings$paths$season_temporal_windows, window_columns, "C.19 concentration windows")
  national_rate <- read_contract_csv(settings$paths$epidemiology_national_summary, national_rate_columns, "C.16 national summary")
  province_rate <- read_contract_csv(settings$paths$epidemiology_province_summary, province_rate_columns, "C.16 province summary")
  region_rate <- read_contract_csv(settings$paths$epidemiology_region_summary, region_rate_columns, "C.16 region summary")

  weekly <- dplyr::filter(weekly, .data$denominator_scenario == settings$scenario) |> dplyr::mutate(season_week_index = parse_count(.data$season_week_index, "season_week_index"), published_row_count = parse_count(.data$published_row_count, "published_row_count"), published_case_count = parse_count(.data$published_case_count, "published_case_count"), geographic_mapping_completeness = parse_number(.data$geographic_mapping_completeness, "geographic_mapping_completeness", 0)) |> dplyr::arrange(.data$season_week_index)
  if (nrow(weekly) != 52L || !identical(as.integer(weekly$season_week_index), 1:52) || any(weekly$geographic_mapping_completeness > 1) || any(weekly$season_scope_id != settings$season_scope_id) || any(weekly$season_label != settings$season_label) || any(weekly$season_indicator_schema_version != "1.0.0")) abort_c20("C.18 weekly national does not match the configured season scope.")
  require_unique_key(weekly, c("season_scope_id", "season_week_index"), "C.18 weekly national")

  if (nrow(season_summary) != 1L || season_summary$season_indicator_schema_version != "1.0.0" || season_summary$season_scope_id != settings$season_scope_id || season_summary$season_label != settings$season_label) abort_c20("Invalid C.18 national summary provenance.")
  season_summary$season_published_row_count <- parse_count(season_summary$season_published_row_count, "season_published_row_count")
  season_summary$season_published_case_count <- parse_count(season_summary$season_published_case_count, "season_published_case_count")
  season_summary$season_week_count <- parse_count(season_summary$season_week_count, "season_week_count")
  season_summary$season_geographic_mapping_completeness <- parse_number(season_summary$season_geographic_mapping_completeness, "season_geographic_mapping_completeness", 0)
  if (season_summary$season_week_count != 52 || season_summary$season_geographic_mapping_completeness > 1 || sum(weekly$published_row_count) != season_summary$season_published_row_count || sum(weekly$published_case_count) != season_summary$season_published_case_count) abort_c20("C.18 national reconciliation failed.")

  if (nrow(national_temporal) != 1L || national_temporal$season_temporal_descriptor_schema_version != "1.0.0" || national_temporal$season_scope_id != settings$season_scope_id || national_temporal$season_label != settings$season_label || national_temporal$national_temporal_coverage_basis != "complete_explicit_season_week_axis") abort_c20("Invalid C.19 national temporal provenance.")
  national_temporal <- dplyr::mutate(national_temporal, national_published_row_count = parse_count(.data$national_published_row_count, "national_published_row_count"), national_published_case_count = parse_count(.data$national_published_case_count, "national_published_case_count"), national_observed_week_count = parse_count(.data$national_observed_week_count, "national_observed_week_count"), peak_count_value = parse_count(.data$peak_count_value, "peak_count_value"), peak_count_season_week_index = parse_count(.data$peak_count_season_week_index, "peak_count_season_week_index"), published_count_weighted_season_week = parse_number(.data$published_count_weighted_season_week, "published_count_weighted_season_week", 1), published_count_weighted_median_season_week = parse_count(.data$published_count_weighted_median_season_week, "published_count_weighted_median_season_week"))
  if (national_temporal$national_published_row_count != season_summary$season_published_row_count || national_temporal$national_published_case_count != season_summary$season_published_case_count || national_temporal$national_observed_week_count != 52 || national_temporal$peak_count_selection_status != "unique_peak" || national_temporal$peak_count_value != max(weekly$published_case_count) || national_temporal$peak_count_season_week_index != weekly$season_week_index[which.max(weekly$published_case_count)] || national_temporal$published_count_weighted_season_week > 52 || national_temporal$published_count_weighted_median_season_week > 52) abort_c20("C.19 national descriptors are incompatible with C.18.")

  windows <- dplyr::mutate(windows, target_share = parse_number(.data$target_share, "target_share", 0), window_start_season_week_index = parse_count(.data$window_start_season_week_index, "window start"), window_end_season_week_index = parse_count(.data$window_end_season_week_index, "window end"), window_length_weeks = parse_count(.data$window_length_weeks, "window length"), window_published_case_count = parse_count(.data$window_published_case_count, "window count"), window_published_case_share = parse_number(.data$window_published_case_share, "window share", 0)) |> dplyr::arrange(.data$target_share)
  if (nrow(windows) != 3L || any(windows$season_temporal_window_schema_version != "1.0.0") || any(windows$season_scope_id != settings$season_scope_id) || !identical(windows$target_share, c(0.5, 0.8, 0.9)) || any(windows$window_length_weeks != windows$window_end_season_week_index - windows$window_start_season_week_index + 1L) || any(windows$window_published_case_share < windows$target_share) || any(windows$window_end_season_week_index > 52L)) abort_c20("Invalid C.19 concentration windows.")
  purrr::walk(seq_len(nrow(windows)), function(index) {
    selected <- dplyr::filter(weekly, .data$season_week_index >= windows$window_start_season_week_index[[index]], .data$season_week_index <= windows$window_end_season_week_index[[index]])
    if (sum(selected$published_case_count) != windows$window_published_case_count[[index]] || abs(sum(selected$published_case_count) / season_summary$season_published_case_count - windows$window_published_case_share[[index]]) > 1e-12) abort_c20("C.19 concentration window does not reconcile to C.18.")
  })

  if (nrow(regional_temporal) != 5L || any(regional_temporal$season_temporal_descriptor_schema_version != "1.0.0") || any(regional_temporal$season_scope_id != settings$season_scope_id) || !setequal(regional_temporal$epidemiological_region, settings$ben_region_order) || any(regional_temporal$regional_temporal_coverage_basis != "observed_region_weeks_only")) abort_c20("Invalid C.19 regional temporal summary.")
  require_unique_key(regional_temporal, "epidemiological_region", "C.19 regional temporal summary")
  regional_temporal <- dplyr::mutate(regional_temporal, regional_observed_week_count = parse_count(.data$regional_observed_week_count, "regional_observed_week_count"), published_count_weighted_season_week = parse_number(.data$published_count_weighted_season_week, "regional weighted center", 1), published_count_weighted_median_season_week = parse_count(.data$published_count_weighted_median_season_week, "regional weighted median"), peak_region_observed_province_count = parse_optional_count(.data$peak_region_observed_province_count, "peak observed province count"), peak_region_total_province_count = parse_optional_count(.data$peak_region_total_province_count, "peak total province count"))
  if (any(regional_temporal$regional_observed_week_count < 1 | regional_temporal$regional_observed_week_count > 52) || any(regional_temporal$published_count_weighted_season_week > 52) || any(regional_temporal$published_count_weighted_median_season_week > 52) || any(xor(is.na(regional_temporal$peak_region_observed_province_count), is.na(regional_temporal$peak_region_total_province_count))) || any(regional_temporal$peak_region_observed_province_count > regional_temporal$peak_region_total_province_count, na.rm = TRUE)) abort_c20("Invalid C.19 regional temporal measures.")

  national_rate <- dplyr::filter(national_rate, .data$source_year == as.character(settings$calendar_year), .data$denominator_scenario == settings$scenario)
  province_rate <- dplyr::filter(province_rate, .data$source_year == as.character(settings$calendar_year), .data$denominator_scenario == settings$scenario)
  region_rate <- dplyr::filter(region_rate, .data$source_year == as.character(settings$calendar_year), .data$denominator_scenario == settings$scenario)
  if (nrow(national_rate) != 1L || nrow(province_rate) != 24L || nrow(region_rate) != 5L || any(c(national_rate$epidemiological_indicator_schema_version, province_rate$epidemiological_indicator_schema_version, region_rate$epidemiological_indicator_schema_version) != "1.0.0") || any(c(national_rate$analysis_scope_id, province_rate$analysis_scope_id, region_rate$analysis_scope_id) != settings$calendar_scope_id) || any(c(national_rate$rate_period_basis, province_rate$rate_period_basis, region_rate$rate_period_basis) != "observed_weeks_01_52")) abort_c20("C.16 inputs do not match the configured calendar-year scope.")
  province_rate <- dplyr::mutate(province_rate, published_case_count = parse_count(.data$published_case_count, "province cases"), published_count_rate_100k = parse_number(.data$published_count_rate_100k, "province rate", 0), published_case_share_of_national = parse_number(.data$published_case_share_of_national, "province share", 0))
  region_rate <- dplyr::mutate(region_rate, published_case_count = parse_count(.data$published_case_count, "region cases"), published_count_rate_100k = parse_number(.data$published_count_rate_100k, "region rate", 0), published_case_share_of_national = parse_number(.data$published_case_share_of_national, "region share", 0))
  national_rate$published_case_count <- parse_count(national_rate$published_case_count, "national 2024 cases")
  require_unique_key(province_rate, c("reference_province_id", "reference_province_name"), "C.16 province summary")
  require_unique_key(region_rate, "epidemiological_region", "C.16 region summary")
  if (any(abs(province_rate$published_case_share_of_national - province_rate$published_case_count / national_rate$published_case_count) > 1e-12) || any(abs(region_rate$published_case_share_of_national - region_rate$published_case_count / national_rate$published_case_count) > 1e-12) || sum(province_rate$published_case_count) > national_rate$published_case_count || sum(region_rate$published_case_count) > national_rate$published_case_count || !setequal(region_rate$epidemiological_region, settings$ben_region_order)) abort_c20("C.16 territorial reconciliation failed.")
  list(weekly = weekly, season_summary = season_summary, national_temporal = national_temporal, regional_temporal = regional_temporal, windows = windows, province_rate = province_rate, region_rate = region_rate)
}

#' Calculate deterministic descending ranks with an explicit identifier tie-break.
rank_measure <- function(table, value_column, output_column) {
  table |> dplyr::arrange(dplyr::desc(.data[[value_column]]), .data$reference_province_id, .data$reference_province_name) |> dplyr::mutate("{output_column}" := dplyr::row_number())
}

#' Validate configured province and region ranking expectations.
validate_rank_expectations <- function(inputs, settings) {
  ranked <- rank_measure(inputs$province_rate, "published_case_count", "count_rank") |> rank_measure("published_count_rate_100k", "rate_rank")
  featured <- dplyr::bind_rows(settings$featured_provinces)
  if (!all(c("reference_province_id", "count_rank", "rate_rank") %in% names(featured)) || nrow(featured) != 4L) abort_c20("Invalid featured-province configuration.")
  checks <- dplyr::left_join(featured, dplyr::select(ranked, reference_province_id, count_rank, rate_rank), by = "reference_province_id", suffix = c("_expected", "_observed"))
  if (any(is.na(checks$count_rank_observed)) || any(as.integer(checks$count_rank_expected) != checks$count_rank_observed) || any(as.integer(checks$rate_rank_expected) != checks$rate_rank_observed)) abort_c20("C.20 province rank regression expectation failed.")
  count_order <- inputs$region_rate |> dplyr::arrange(dplyr::desc(.data$published_case_count), .data$epidemiological_region)
  rate_order <- inputs$region_rate |> dplyr::arrange(dplyr::desc(.data$published_count_rate_100k), .data$epidemiological_region)
  expected <- settings$regional_expectations
  if (!identical(count_order$epidemiological_region[[1]], expected$highest_published_count) || !identical(rate_order$epidemiological_region[[1]], expected$highest_published_count_rate) || !identical(rate_order$epidemiological_region[[2]], expected$second_highest_published_count_rate)) abort_c20("C.20 regional rank regression expectation failed.")
  list(province = ranked, region_count_order = count_order$epidemiological_region)
}

#' Build the national seasonal profile figure.
build_season_national_plot <- function(inputs, settings) {
  weekly <- inputs$weekly
  descriptor <- inputs$national_temporal
  text <- localized_strings(settings$language)
  windows <- dplyr::mutate(inputs$windows, track = -max(weekly$published_case_count) * c(0.04, 0.08, 0.12), label = sprintf("%s %%: SE%s–SE%s (%s %s)", format_number(.data$target_share * 100, language = settings$language), .data$window_start_season_week_index, .data$window_end_season_week_index, .data$window_length_weeks, text$weeks))
  labels <- weekly |> dplyr::filter(.data$season_week_index %in% c(1L, 9L, 17L, 22L, 23L, 31L, 39L, 47L, 52L)) |> dplyr::transmute(season_week_index, label = sprintf("%s-W%02d", .data$source_year, as.integer(.data$source_week)))
  peak <- dplyr::filter(weekly, .data$season_week_index == descriptor$peak_count_season_week_index)
  ggplot2::ggplot(weekly, ggplot2::aes(x = .data$season_week_index, y = .data$published_case_count)) +
    ggplot2::geom_line(linewidth = 1.2, colour = "#1F5A7A") + ggplot2::geom_point(size = 1.8, colour = "#1F5A7A") +
    ggplot2::geom_vline(xintercept = 22.5, linetype = "dashed", linewidth = 0.45, colour = "#7A7A7A") +
    ggplot2::geom_vline(xintercept = descriptor$published_count_weighted_season_week, linetype = "dashed", linewidth = 0.9, colour = "#6A3D9A") +
    ggplot2::geom_vline(xintercept = descriptor$published_count_weighted_median_season_week, linetype = "dotted", linewidth = 1.1, colour = "#2E6F40") +
    ggplot2::geom_point(data = peak, size = 4.2, shape = 21, fill = "#B13F2D", colour = "#B13F2D") +
    ggplot2::geom_label(data = peak, ggplot2::aes(label = sprintf("%s: SE%s\n%s %s", text$observed_peak, .data$season_week_index, format_number(.data$published_case_count, language = settings$language), text$published_counts)), fill = "white", colour = "#173042", size = 4.5, vjust = -0.55, show.legend = FALSE) +
    ggplot2::annotate("label", x = descriptor$published_count_weighted_season_week - 0.4, y = max(weekly$published_case_count) * 0.78, label = sprintf("%s\nSE %s", text$weighted_center, format_number(descriptor$published_count_weighted_season_week, 2, settings$language)), colour = "#6A3D9A", fill = "white", size = 3.9, hjust = 1) +
    ggplot2::annotate("label", x = descriptor$published_count_weighted_median_season_week + 0.4, y = max(weekly$published_case_count) * 0.63, label = sprintf("%s\nSE %s", text$weighted_median, descriptor$published_count_weighted_median_season_week), colour = "#2E6F40", fill = "white", size = 3.9, hjust = 0) +
    ggplot2::geom_segment(data = windows, ggplot2::aes(x = .data$window_start_season_week_index, xend = .data$window_end_season_week_index, y = .data$track, yend = .data$track), inherit.aes = FALSE, linewidth = 2.2, colour = "#405364") +
    ggplot2::geom_text(data = windows, ggplot2::aes(x = 52.4, y = .data$track, label = .data$label), inherit.aes = FALSE, hjust = 0, size = 3.7, colour = "#405364") +
    ggplot2::scale_x_continuous(breaks = labels$season_week_index, labels = labels$label, limits = c(1, 67), guide = ggplot2::guide_axis(n.dodge = 2)) +
    ggplot2::scale_y_continuous(labels = function(values) format_number(values, language = settings$language), limits = c(-0.16 * max(weekly$published_case_count), NA), expand = ggplot2::expansion(mult = c(0, 0.18))) +
    ggplot2::labs(title = text$season_title, subtitle = sprintf("%s %s · %s %s · %s: %s %%", text$season_scope, settings$season_label, format_number(inputs$season_summary$season_published_case_count, language = settings$language), text$published_counts, text$mapping_completeness, format_number(100 * inputs$season_summary$season_geographic_mapping_completeness, 1, settings$language)), x = text$season_week, y = text$published_counts, caption = text$national_caption) +
    portfolio_theme()
}

#' Expand contractually tied peak indices without selecting an arbitrary week.
expand_peak_indices <- function(regions, text) {
  purrr::map_dfr(seq_len(nrow(regions)), function(index) {
    values <- as.integer(strsplit(regions$peak_count_tied_season_week_indices[[index]], "\\|", fixed = FALSE)[[1]])
    tibble::tibble(epidemiological_region = regions$epidemiological_region[[index]], season_week_index = values, descriptor = if (length(values) == 1L) text$observed_peak else text$peak_tie)
  })
}

#' Build the observed regional timing figure.
build_season_regional_plot <- function(inputs, settings) {
  text <- localized_strings(settings$language)
  regions <- inputs$regional_temporal |> dplyr::mutate(epidemiological_region = factor(.data$epidemiological_region, levels = rev(settings$ben_region_order)), coverage = ifelse(is.na(.data$peak_region_observed_province_count), sprintf("%s %s · %s", .data$regional_observed_week_count, text$observed_weeks, text$tied_peak), sprintf("%s %s · %s/%s %s", .data$regional_observed_week_count, text$observed_weeks, .data$peak_region_observed_province_count, .data$peak_region_total_province_count, text$provinces_at_peak)))
  peaks <- expand_peak_indices(regions, text) |> dplyr::mutate(epidemiological_region = factor(.data$epidemiological_region, levels = levels(regions$epidemiological_region)))
  other <- dplyr::bind_rows(dplyr::transmute(regions, epidemiological_region, season_week_index = .data$published_count_weighted_median_season_week, descriptor = text$weighted_median), dplyr::transmute(regions, epidemiological_region, season_week_index = .data$published_count_weighted_season_week, descriptor = text$weighted_center))
  ggplot2::ggplot() +
    ggplot2::geom_point(data = peaks, ggplot2::aes(x = .data$season_week_index, y = .data$epidemiological_region, shape = .data$descriptor), size = 4.2, colour = "#B13F2D", fill = "white") +
    ggplot2::geom_point(data = other, ggplot2::aes(x = .data$season_week_index, y = .data$epidemiological_region, shape = .data$descriptor), size = 3.6, colour = "#1F5A7A") +
    ggplot2::geom_text(data = regions, ggplot2::aes(x = 55, y = .data$epidemiological_region, label = .data$coverage), hjust = 0, size = 4, colour = "#405364") +
    ggplot2::scale_shape_manual(values = stats::setNames(c(21, 21, 24, 23), c(text$observed_peak, text$peak_tie, text$weighted_median, text$weighted_center)), name = NULL) +
    ggplot2::scale_x_continuous(breaks = seq(1, 52, by = 4), limits = c(1, 70)) +
    ggplot2::labs(title = text$regional_title, subtitle = sprintf("%s %s · %s", text$season_scope, settings$season_label, text$tied_subtitle), x = text$season_week, y = NULL, caption = text$regional_caption) +
    portfolio_theme() + ggplot2::theme(panel.grid.major.y = ggplot2::element_line(colour = "#D9E1E6", linewidth = 0.35), legend.position = "bottom")
}

#' Build the provincial count-to-rate rank-shift figure.
build_province_rank_plot <- function(ranked, settings) {
  text <- localized_strings(settings$language)
  highlighted <- dplyr::filter(ranked, .data$reference_province_id %in% purrr::map_chr(settings$featured_provinces, "reference_province_id"))
  positions <- dplyr::bind_rows(dplyr::transmute(ranked, reference_province_id, reference_province_name, axis = "Rango por conteos publicados", x = 1, rank = .data$count_rank), dplyr::transmute(ranked, reference_province_id, reference_province_name, axis = "Rango por tasa por 100.000", x = 2, rank = .data$rate_rank))
  ggplot2::ggplot(positions, ggplot2::aes(x = .data$x, y = .data$rank, group = .data$reference_province_id)) +
    ggplot2::geom_line(colour = "#B8C4CC", linewidth = 0.7) + ggplot2::geom_point(shape = 21, fill = "white", colour = "#7A7A7A", size = 2.5) +
    ggplot2::geom_line(data = dplyr::filter(positions, .data$reference_province_id %in% highlighted$reference_province_id), colour = "#B13F2D", linewidth = 1.25) +
    ggplot2::geom_point(data = dplyr::filter(positions, .data$reference_province_id %in% highlighted$reference_province_id), shape = 21, fill = "#B13F2D", colour = "#B13F2D", size = 3.6) +
    ggplot2::geom_text(data = highlighted, ggplot2::aes(x = 0.92, y = .data$count_rank, label = sprintf("%s · %s", .data$reference_province_name, format_number(.data$published_case_count, language = settings$language))), inherit.aes = FALSE, hjust = 1, size = 3.8, colour = "#173042") +
    ggplot2::geom_text(data = highlighted, ggplot2::aes(x = 2.08, y = .data$rate_rank, label = sprintf("%s · %s", .data$reference_province_name, format_number(.data$published_count_rate_100k, 1, settings$language))), inherit.aes = FALSE, hjust = 0, size = 3.8, colour = "#173042") +
    ggplot2::scale_x_continuous(breaks = c(1, 2), labels = c(text$count_rank, text$rate_rank), limits = c(0.35, 2.75)) +
    ggplot2::scale_y_reverse(breaks = seq_len(nrow(ranked)), limits = c(nrow(ranked) + 0.5, 0.5)) +
    ggplot2::labs(title = text$rank_title, subtitle = sprintf("%s %s · %s %s", text$calendar_year, settings$calendar_year, text$denominator_scenario, settings$scenario), x = NULL, y = text$rank_axis, caption = text$rate_caption) +
    portfolio_theme() + ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
}

#' Build the regional count-and-rate burden figure.
build_region_burden_plot <- function(inputs, region_order, settings) {
  text <- localized_strings(settings$language)
  regions <- inputs$region_rate |> dplyr::mutate(epidemiological_region = factor(.data$epidemiological_region, levels = rev(region_order)))
  values <- dplyr::bind_rows(dplyr::transmute(regions, epidemiological_region, measure = text$counts, value = .data$published_case_count, label = format_number(.data$published_case_count, language = settings$language)), dplyr::transmute(regions, epidemiological_region, measure = text$rate, value = .data$published_count_rate_100k, label = format_number(.data$published_count_rate_100k, 1, settings$language)))
  ggplot2::ggplot(values, ggplot2::aes(x = .data$value, y = .data$epidemiological_region)) +
    ggplot2::geom_segment(ggplot2::aes(x = 0, xend = .data$value, yend = .data$epidemiological_region), linewidth = 1.1, colour = "#B8C4CC") +
    ggplot2::geom_point(shape = 21, fill = "#1F5A7A", colour = "#1F5A7A", size = 4) +
    ggplot2::geom_text(ggplot2::aes(label = .data$label), hjust = -0.2, size = 4, colour = "#173042") +
    ggplot2::facet_wrap(ggplot2::vars(.data$measure), scales = "free_x", nrow = 1L) +
    ggplot2::scale_x_continuous(labels = function(values) format_number(values, language = settings$language), expand = ggplot2::expansion(mult = c(0, 0.16))) +
    ggplot2::labs(title = text$region_title, subtitle = sprintf("%s %s · %s %s", text$calendar_year, settings$calendar_year, text$denominator_scenario, settings$scenario), x = NULL, y = NULL, caption = text$region_caption) +
    portfolio_theme() + ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
}

#' Render one plot to a controlled PNG file.
render_png <- function(plot, path, dimensions, dpi) {
  device_open <- FALSE
  on.exit(if (device_open) grDevices::dev.off(), add = TRUE)
  tryCatch({ grDevices::png(path, width = dimensions[["width"]], height = dimensions[["height"]], units = "px", res = dpi, type = "cairo"); device_open <- TRUE; print(plot); grDevices::dev.off(); device_open <- FALSE }, error = function(error) abort_c20(sprintf("Could not render PNG: %s", error$message)))
}

#' Validate the PNG signature, dimensions, and non-zero size.
validate_png <- function(path, dimensions) {
  if (!file.exists(path) || file.info(path)$size <= 0) abort_c20("Rendered PNG is absent or empty.")
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  bytes <- readBin(connection, what = "raw", n = 24L)
  if (length(bytes) != 24L || !identical(bytes[1:8], as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))) || rawToChar(bytes[13:16]) != "IHDR") abort_c20("Rendered file is not a valid PNG.")
  decode <- function(raw) sum(as.integer(raw) * c(256^3, 256^2, 256, 1))
  if (decode(bytes[17:20]) != dimensions[["width"]] || decode(bytes[21:24]) != dimensions[["height"]]) abort_c20("Rendered PNG dimensions are incorrect.")
}

#' Publish a coherent output set, restoring prior files after controlled failure.
publish_figure_set <- function(temporary_paths, output_paths) {
  backups <- purrr::imap_chr(output_paths, function(path, name) if (file.exists(path)) tempfile(paste0(".argentina_dengue_c20_", name, "_backup_"), dirname(path), ".png") else NA_character_)
  published <- character()
  restore <- function() { purrr::walk(published, ~ if (file.exists(.x)) unlink(.x)); purrr::iwalk(backups[!is.na(backups)], function(backup, name) if (file.exists(backup)) file.rename(backup, output_paths[[name]])) }
  tryCatch({
    purrr::iwalk(backups[!is.na(backups)], function(backup, name) { if (!file.rename(output_paths[[name]], backup)) abort_c20(sprintf("Could not protect existing C.20 figure: %s", name)) })
    purrr::iwalk(output_paths, function(path, name) { if (!file.rename(temporary_paths[[name]], path)) abort_c20(sprintf("Could not publish C.20 figure: %s", name)); published <<- c(published, path) })
  }, error = function(error) { restore(); abort_c20(error$message) })
  unlink(backups[!is.na(backups)])
}

#' Run C.20 from the project root.
main <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) abort_c20("Required direct dependency ggplot2 is not available.")
  config <- read_project_config()
  argument <- commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--language=")]
  language <- if (length(argument)) sub("^--language=", "", argument[[1]]) else config$epidemiological_portfolio_visualization$default_language
  settings <- visualization_settings(config, language)
  inputs <- read_and_validate_inputs(settings)
  ranks <- validate_rank_expectations(inputs, settings)
  plots <- list(
    season_national_temporal_profile = build_season_national_plot(inputs, settings),
    season_regional_observed_timing = build_season_regional_plot(inputs, settings),
    province_count_rate_rank_shift_2024 = build_province_rank_plot(ranks$province, settings),
    region_population_adjusted_burden_2024 = build_region_burden_plot(inputs, ranks$region_count_order, settings)
  )
  temporary_paths <- purrr::imap_chr(settings$outputs, function(path, name) { dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE); tempfile(paste0(".argentina_dengue_c20_", name, "_"), dirname(path), ".png") })
  on.exit(unlink(temporary_paths), add = TRUE)
  purrr::iwalk(plots, function(plot, name) { render_png(plot, temporary_paths[[name]], figure_dimensions[[name]], settings$dpi); validate_png(temporary_paths[[name]], figure_dimensions[[name]]) })
  publish_figure_set(temporary_paths, settings$outputs)
  message(sprintf("language=%s | season_scope=%s | calendar_scope=%s | figures=%s", settings$language, settings$season_scope_id, settings$calendar_scope_id, length(plots)))
  invisible(TRUE)
}

if (length(commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]) == 1L && basename(sub("^--file=", "", commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")])) == "20_generate_epidemiological_portfolio_figures.R") main()
