###############################################################
# Argentina Dengue Analysis
# Script: 08_generate_figures.R
# Purpose: Render curated descriptive portfolio figures from C.9 tables.
# Inputs: project configuration and four analysis-table artifacts.
# Outputs: four versioned PNG figures in figures/.
###############################################################

table_columns <- list(
  weekly_national = c(
    "analysis_table_schema_version", "analysis_scope_id", "source_resource_id",
    "source_year", "source_week", "published_row_count", "published_case_count"
  ),
  province_summary = c(
    "analysis_table_schema_version", "analysis_scope_id", "source_resource_id",
    "source_year", "province_id", "province_name", "published_row_count",
    "published_case_count", "published_case_share"
  ),
  weekly_province = c(
    "analysis_table_schema_version", "analysis_scope_id", "source_resource_id",
    "source_year", "source_week", "province_id", "province_name",
    "published_row_count", "published_case_count"
  ),
  age_group_summary = c(
    "analysis_table_schema_version", "analysis_scope_id", "source_resource_id",
    "source_year", "source_age_group_id", "source_age_group_label",
    "published_row_count", "published_case_count", "published_case_share"
  )
)

figure_dimensions <- list(
  weekly_national = c(width = 2400L, height = 1350L),
  province_ranking = c(width = 2400L, height = 1800L),
  top5_provinces_weekly = c(width = 2400L, height = 1800L),
  age_group_composition = c(width = 2400L, height = 1800L)
)

share_tolerance <- 1e-12
primary_scope_id <- "primary_dengue_2024"
primary_source_year <- 2024L
main_colour <- "#1F5A7A"
accent_colour <- "#B13F2D"
unspecified_colour <- "#7A7A7A"

#' Stop visualization with a contract-specific execution error.
#'
#' @param message Error message.
#' @return This function does not return.
abort_visualization <- function(message) {
  stop(message, call. = FALSE)
}

#' Read project configuration from its fixed bootstrap path.
#'
#' @return Parsed YAML configuration.
read_project_config <- function() {
  if (!file.exists("config/project.yml")) {
    abort_visualization("Configuration file not found: config/project.yml")
  }
  tryCatch(
    yaml::read_yaml("config/project.yml"),
    error = function(error) abort_visualization(sprintf("Could not read configuration: %s", error$message))
  )
}

#' Retrieve one required scalar configuration string.
#'
#' @param config Parsed YAML configuration.
#' @param section First-level configuration section.
#' @param key Required key within the section.
#' @return Trimmed string.
required_string <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (is.null(value) || length(value) != 1L || !is.character(value) || is.na(value) || !nzchar(trimws(value))) {
    abort_visualization(sprintf("Missing or invalid configuration value: %s.%s", section, key))
  }
  trimws(value)
}

#' Retrieve one required positive integer configuration value.
#'
#' @param config Parsed YAML configuration.
#' @param section First-level configuration section.
#' @param key Required key within the section.
#' @return Integer scalar.
required_positive_integer <- function(config, section, key) {
  value <- config[[section]][[key]]
  if (is.null(value) || length(value) != 1L || is.na(value) || !is.numeric(value) || value < 1 || value != floor(value)) {
    abort_visualization(sprintf("Missing or invalid positive integer configuration value: %s.%s", section, key))
  }
  as.integer(value)
}

#' Require a configuration path to be project-relative.
#'
#' @param path Configured path.
#' @param label Configuration label.
#' @return Invisibly returns the path.
require_relative_path <- function(path, label) {
  if (grepl("^(/|[[:alpha:]]:[/\\\\])", path)) {
    abort_visualization(sprintf("%s must be relative to the project root: %s", label, path))
  }
  invisible(path)
}

#' Determine whether a path is contained by a configured project directory.
#'
#' @param path Candidate project-relative path.
#' @param directory Project-relative parent directory.
#' @return Logical scalar.
inside_directory <- function(path, directory) {
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  candidate <- normalizePath(file.path(root, path), winslash = "/", mustWork = FALSE)
  parent <- normalizePath(file.path(root, directory), winslash = "/", mustWork = FALSE)
  startsWith(candidate, paste0(parent, "/"))
}

#' Validate and collect C.10 configuration paths and rendering settings.
#'
#' @param config Parsed YAML configuration.
#' @return Named list of paths and resolution.
visualization_config <- function(config) {
  settings <- list(
    processed_directory = required_string(config, "directories", "processed_data"),
    figures_directory = required_string(config, "directories", "figures"),
    weekly_national_path = required_string(config, "artifacts", "analysis_weekly_national"),
    province_summary_path = required_string(config, "artifacts", "analysis_province_summary"),
    weekly_province_path = required_string(config, "artifacts", "analysis_weekly_province"),
    age_group_summary_path = required_string(config, "artifacts", "analysis_age_group_summary"),
    weekly_national_figure_path = required_string(config, "artifacts", "dengue_2024_weekly_national_figure"),
    province_ranking_figure_path = required_string(config, "artifacts", "dengue_2024_province_ranking_figure"),
    top5_provinces_weekly_figure_path = required_string(config, "artifacts", "dengue_2024_top5_provinces_weekly_figure"),
    age_group_composition_figure_path = required_string(config, "artifacts", "dengue_2024_age_group_composition_figure"),
    resolution_dpi = required_positive_integer(config, "visualization", "png_resolution_dpi")
  )
  purrr::iwalk(settings[vapply(settings, is.character, logical(1))], require_relative_path)
  input_paths <- settings[c("weekly_national_path", "province_summary_path", "weekly_province_path", "age_group_summary_path")]
  output_paths <- settings[c("weekly_national_figure_path", "province_ranking_figure_path", "top5_provinces_weekly_figure_path", "age_group_composition_figure_path")]
  if (any(!vapply(input_paths, inside_directory, logical(1), directory = settings$processed_directory))) {
    abort_visualization("Visualization inputs must belong to the processed-data directory.")
  }
  if (any(!vapply(output_paths, inside_directory, logical(1), directory = settings$figures_directory))) {
    abort_visualization("Visualization outputs must belong to the figures directory.")
  }
  root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  resolved_outputs <- vapply(output_paths, function(path) normalizePath(file.path(root, path), winslash = "/", mustWork = FALSE), character(1))
  if (anyDuplicated(resolved_outputs)) {
    abort_visualization("Visualization output paths must be distinct.")
  }
  settings
}

#' Parse strict decimal integer values within a contractual range.
#'
#' @param values Character values to parse.
#' @param field Field name for diagnostics.
#' @param minimum Minimum accepted value.
#' @param maximum Maximum accepted value.
#' @return Integer vector.
parse_contract_integer <- function(values, field, minimum, maximum = .Machine$integer.max) {
  if (any(is.na(values)) || any(!grepl("^[0-9]+$", values))) {
    abort_visualization(sprintf("C.9 field %s is missing or not a decimal integer.", field))
  }
  parsed <- suppressWarnings(as.integer(values))
  if (any(is.na(parsed)) || any(parsed < minimum | parsed > maximum)) {
    abort_visualization(sprintf("C.9 field %s is outside its contractual range.", field))
  }
  parsed
}

#' Parse finite decimal shares in the closed unit interval.
#'
#' @param values Character values to parse.
#' @param table_name Contractual table name for diagnostics.
#' @return Numeric vector.
parse_contract_share <- function(values, table_name) {
  parsed <- suppressWarnings(as.numeric(values))
  if (any(is.na(parsed)) || any(!is.finite(parsed)) || any(parsed < 0 | parsed > 1)) {
    abort_visualization(sprintf("C.9 table has invalid published_case_share values: %s", table_name))
  }
  parsed
}

#' Require non-missing, non-empty textual values in one C.9 field.
#'
#' @param table Input tibble.
#' @param column Field name.
#' @param table_name Contractual table name for diagnostics.
#' @return Invisibly TRUE when valid.
require_text <- function(table, column, table_name) {
  if (any(is.na(table[[column]]) | !nzchar(table[[column]]))) {
    abort_visualization(sprintf("C.9 table has missing required text in %s: %s", column, table_name))
  }
  invisible(TRUE)
}

#' Require a C.9 logical key to be unique.
#'
#' @param table Input tibble.
#' @param key_columns Ordered key columns.
#' @param table_name Contractual table name for diagnostics.
#' @return Invisibly TRUE when valid.
require_unique_key <- function(table, key_columns, table_name) {
  if (anyDuplicated(table[key_columns])) {
    abort_visualization(sprintf("C.9 table has duplicate logical keys: %s", table_name))
  }
  invisible(TRUE)
}

#' Validate deterministic ordering of a C.9 table.
#'
#' @param table Input tibble.
#' @param table_name Contractual table name.
#' @return Invisibly TRUE when valid.
validate_table_order <- function(table, table_name) {
  ordered <- switch(
    table_name,
    weekly_national = dplyr::arrange(table, .data$source_year, .data$source_week),
    province_summary = dplyr::arrange(table, .data$source_year, .data$province_id, .data$province_name),
    weekly_province = dplyr::arrange(table, .data$source_year, .data$source_week, .data$province_id, .data$province_name),
    age_group_summary = dplyr::arrange(table, .data$source_year, .data$.age_group_order, .data$source_age_group_label),
    abort_visualization(sprintf("Unknown C.9 table: %s", table_name))
  )
  if (!identical(table, ordered)) {
    abort_visualization(sprintf("C.9 table has non-deterministic ordering: %s", table_name))
  }
  invisible(TRUE)
}

#' Read and validate one C.9 analysis-table artifact.
#'
#' @param path Configured input path.
#' @param table_name Contractual table name.
#' @return Typed and validated tibble.
read_analysis_table <- function(path, table_name) {
  expected_columns <- table_columns[[table_name]]
  if (is.null(expected_columns) || !file.exists(path) || isTRUE(file.info(path)$isdir)) {
    abort_visualization(sprintf("C.9 analysis table is missing or invalid: %s", table_name))
  }
  table <- tryCatch(
    readr::read_csv(path, show_col_types = FALSE, col_types = readr::cols(.default = readr::col_character())),
    error = function(error) abort_visualization(sprintf("Could not read C.9 table %s: %s", table_name, error$message))
  )
  if (!identical(names(table), expected_columns) || nrow(readr::problems(table)) || !nrow(table) || any(table$analysis_table_schema_version != "1.0.0")) {
    abort_visualization(sprintf("C.9 table does not satisfy analysis_table_derivation schema 1.0.0: %s", table_name))
  }
  purrr::walk(c("analysis_scope_id", "source_resource_id"), function(column) {
    require_text(table, column, table_name)
  })
  table$source_year <- parse_contract_integer(table$source_year, "source_year", 1000L, 9999L)
  table$published_row_count <- parse_contract_integer(table$published_row_count, "published_row_count", 1L)
  table$published_case_count <- parse_contract_integer(table$published_case_count, "published_case_count", 0L)
  if (table_name %in% c("weekly_national", "weekly_province")) {
    table$source_week <- parse_contract_integer(table$source_week, "source_week", 1L, 53L)
  }
  if (table_name %in% c("province_summary", "weekly_province")) {
    purrr::walk(c("province_id", "province_name"), function(column) {
      require_text(table, column, table_name)
    })
  }
  if (table_name == "age_group_summary") {
    purrr::walk(c("source_age_group_id", "source_age_group_label"), function(column) {
      require_text(table, column, table_name)
    })
    table$.age_group_order <- parse_contract_integer(table$source_age_group_id, "source_age_group_id", 0L)
  }
  if ("published_case_share" %in% names(table)) {
    table$published_case_share <- parse_contract_share(table$published_case_share, table_name)
  }
  key_columns <- switch(
    table_name,
    weekly_national = c("analysis_scope_id", "source_resource_id", "source_year", "source_week"),
    province_summary = c("analysis_scope_id", "source_resource_id", "source_year", "province_id", "province_name"),
    weekly_province = c("analysis_scope_id", "source_resource_id", "source_year", "source_week", "province_id", "province_name"),
    age_group_summary = c("analysis_scope_id", "source_resource_id", "source_year", "source_age_group_id", "source_age_group_label")
  )
  require_unique_key(table, key_columns, table_name)
  validate_table_order(table, table_name)
  table
}

#' Validate shared C.9 provenance, reconciliation, and share invariants.
#'
#' @param tables Named list of four typed C.9 tables.
#' @return Named list of validated common provenance and totals.
validate_analysis_tables <- function(tables) {
  common_values <- purrr::map(tables, function(table) {
    list(
      scope = unique(table$analysis_scope_id),
      resource = unique(table$source_resource_id),
      year = unique(table$source_year)
    )
  })
  if (any(vapply(common_values, function(value) length(value$scope) != 1L || length(value$resource) != 1L || length(value$year) != 1L, logical(1)))) {
    abort_visualization("Each C.9 table must identify exactly one scope, resource, and source year.")
  }
  scope <- common_values[[1]]$scope[[1]]
  resource <- common_values[[1]]$resource[[1]]
  year <- common_values[[1]]$year[[1]]
  if (!all(vapply(common_values, function(value) identical(value$scope[[1]], scope) && identical(value$resource[[1]], resource) && identical(value$year[[1]], year), logical(1)))) {
    abort_visualization("C.9 tables do not agree on scope, resource, and source year.")
  }
  if (!identical(scope, primary_scope_id) || !identical(year, primary_source_year)) {
    abort_visualization("C.9 regression check failed: current visualization requires primary_dengue_2024 and source year 2024.")
  }
  totals <- purrr::map(tables, function(table) c(rows = sum(table$published_row_count), cases = sum(table$published_case_count)))
  reference_total <- totals[[1]]
  if (!all(vapply(totals, identical, logical(1), y = reference_total))) {
    abort_visualization("C.9 analysis-table reconciliation failed across published rows or counts.")
  }
  purrr::walk(c("province_summary", "age_group_summary"), function(name) {
    table <- tables[[name]]
    expected_share <- table$published_case_count / reference_total[["cases"]]
    if (abs(sum(table$published_case_share) - 1) > share_tolerance || any(abs(table$published_case_share - expected_share) > share_tolerance)) {
      abort_visualization(sprintf("C.9 published-case-share invariant failed: %s", name))
    }
  })
  list(scope = scope, resource = resource, year = year, total_rows = reference_total[["rows"]], total_cases = reference_total[["cases"]])
}

#' Require unambiguous provincial categories across C.9 tables.
#'
#' @param province_summary Provincial summary table.
#' @param weekly_province Provincial weekly table.
#' @return Invisibly TRUE when valid.
validate_province_categories <- function(province_summary, weekly_province) {
  mapping <- dplyr::bind_rows(
    dplyr::select(province_summary, province_id, province_name),
    dplyr::select(weekly_province, province_id, province_name)
  ) |>
    dplyr::distinct() |>
    dplyr::count(.data$province_id, name = "name_count")
  if (any(mapping$name_count != 1L) || !nrow(dplyr::filter(province_summary, .data$province_id != "99"))) {
    abort_visualization("C.9 provincial categories are ambiguous or contain no known province.")
  }
  invisible(TRUE)
}

#' Format published counts for Spanish-language labels.
#'
#' @param values Numeric values.
#' @return Character vector with a period thousands separator.
format_count <- function(values) {
  format(values, big.mark = ".", decimal.mark = ",", trim = TRUE, scientific = FALSE)
}

#' Format source-week values as W01 through W53.
#'
#' @param values Integer week values.
#' @return Character week labels.
format_week <- function(values) {
  sprintf("W%02d", as.integer(values))
}

#' Construct the common sober portfolio theme.
#'
#' @return A ggplot2 theme object.
portfolio_theme <- function() {
  ggplot2::theme_minimal(base_size = 20, base_family = "sans") +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", colour = "#173042", margin = ggplot2::margin(b = 8)),
      plot.subtitle = ggplot2::element_text(colour = "#405364", margin = ggplot2::margin(b = 14)),
      plot.caption = ggplot2::element_text(colour = "#405364", hjust = 0, margin = ggplot2::margin(t = 14)),
      axis.title = ggplot2::element_text(face = "bold", colour = "#173042"),
      axis.text = ggplot2::element_text(colour = "#405364"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "#D9E1E6", linewidth = 0.35),
      panel.grid.major.y = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold", colour = "#173042"),
      strip.background = ggplot2::element_rect(fill = "#EEF3F6", colour = NA),
      plot.margin = ggplot2::margin(24, 36, 24, 24)
    )
}

#' Build the national weekly published-count figure.
#'
#' @param weekly Validated national weekly table.
#' @return ggplot object.
build_weekly_national_plot <- function(weekly) {
  peak <- weekly |>
    dplyr::arrange(dplyr::desc(.data$published_case_count), .data$source_week) |>
    dplyr::slice(1L)
  ggplot2::ggplot(weekly, ggplot2::aes(x = .data$source_week, y = .data$published_case_count)) +
    ggplot2::geom_line(linewidth = 1.25, colour = main_colour) +
    ggplot2::geom_point(size = 2.2, colour = main_colour) +
    ggplot2::geom_point(data = peak, size = 4.2, colour = accent_colour) +
    ggplot2::geom_label(
      data = peak,
      ggplot2::aes(label = sprintf("Pico %s\n%s conteos publicados", format_week(.data$source_week), format_count(.data$published_case_count))),
      colour = "#173042", fill = "white", linewidth = 0.25, size = 5.2,
      vjust = -0.65, show.legend = FALSE
    ) +
    ggplot2::scale_x_continuous(breaks = c(1, 12, 26, 39, 52), labels = format_week, limits = c(1, 52)) +
    ggplot2::scale_y_continuous(labels = format_count, limits = c(0, NA), expand = ggplot2::expansion(mult = c(0, 0.18))) +
    ggplot2::labs(
      title = "Dengue 2024: conteos publicados por semana",
      subtitle = "Fuerte concentración durante la primera mitad del año; máximo en W12",
      x = "Semana epidemiológica fuente", y = "Conteos publicados",
      caption = "Primary scope 2024. Conteos publicados; no representan personas únicas ni tasas."
    ) +
    portfolio_theme()
}

#' Build the known-province ranking figure and its separate unknown-geography note.
#'
#' @param province_summary Validated provincial summary table.
#' @param total_cases Full-scope published-count total.
#' @return ggplot object.
build_province_ranking_plot <- function(province_summary, total_cases) {
  known <- province_summary |>
    dplyr::filter(.data$province_id != "99") |>
    dplyr::arrange(dplyr::desc(.data$published_case_count), .data$province_id, .data$province_name) |>
    dplyr::mutate(province_name = factor(.data$province_name, levels = rev(.data$province_name)))
  unknown <- dplyr::filter(province_summary, .data$province_id == "99")
  unknown_caption <- if (nrow(unknown) == 1L) {
    sprintf("Geografía provincial desconocida: %s conteos publicados (%.2f %% del total nacional).", format_count(unknown$published_case_count[[1]]), 100 * unknown$published_case_count[[1]] / total_cases)
  } else {
    "No se presenta como provincia ninguna categoría de geografía desconocida."
  }
  top_three_share <- 100 * sum(head(known$published_case_count, 3L)) / total_cases
  ggplot2::ggplot(known, ggplot2::aes(x = .data$province_name, y = .data$published_case_count)) +
    ggplot2::geom_col(fill = main_colour, width = 0.72) +
    ggplot2::geom_text(ggplot2::aes(label = format_count(.data$published_case_count)), hjust = -0.12, size = 4.5, colour = "#173042") +
    ggplot2::coord_flip(clip = "off") +
    ggplot2::scale_y_continuous(labels = format_count, limits = c(0, NA), expand = ggplot2::expansion(mult = c(0, 0.13))) +
    ggplot2::labs(
      title = "Dengue 2024: conteos publicados por jurisdicción reportada",
      subtitle = sprintf("Buenos Aires, Córdoba y Tucumán concentran %.2f %% del total publicado", top_three_share),
      x = NULL, y = "Conteos publicados",
      caption = paste("Primary scope 2024. El ranking no mide riesgo provincial.", unknown_caption, sep = "\n")
    ) +
    portfolio_theme() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
}

#' Build fixed-scale top-five provincial weekly small multiples.
#'
#' @param province_summary Validated provincial summary table.
#' @param weekly_province Validated provincial weekly table.
#' @return ggplot object.
build_top_provinces_weekly_plot <- function(province_summary, weekly_province) {
  top_provinces <- province_summary |>
    dplyr::filter(.data$province_id != "99") |>
    dplyr::arrange(dplyr::desc(.data$published_case_count), .data$province_id, .data$province_name) |>
    dplyr::slice_head(n = 5L) |>
    dplyr::select(province_id, province_name)
  top_weekly <- weekly_province |>
    dplyr::inner_join(top_provinces, by = c("province_id", "province_name")) |>
    dplyr::arrange(.data$province_id, .data$source_week) |>
    dplyr::group_by(.data$province_id, .data$province_name) |>
    dplyr::mutate(.segment_id = cumsum(c(TRUE, diff(.data$source_week) != 1L))) |>
    dplyr::ungroup() |>
    dplyr::mutate(province_name = factor(.data$province_name, levels = top_provinces$province_name))
  peaks <- top_weekly |>
    dplyr::group_by(.data$province_id, .data$province_name) |>
    dplyr::arrange(dplyr::desc(.data$published_case_count), .data$source_week, .by_group = TRUE) |>
    dplyr::slice(1L) |>
    dplyr::ungroup() |>
    dplyr::mutate(.label_vjust = ifelse(.data$published_case_count > 0.65 * max(top_weekly$published_case_count), 1.4, -0.6))
  ggplot2::ggplot(top_weekly, ggplot2::aes(x = .data$source_week, y = .data$published_case_count)) +
    ggplot2::geom_line(ggplot2::aes(group = .data$.segment_id), linewidth = 1.05, colour = main_colour) +
    ggplot2::geom_point(size = 1.6, colour = main_colour) +
    ggplot2::geom_point(data = peaks, size = 3.2, colour = accent_colour) +
    ggplot2::geom_label(
      data = peaks,
      ggplot2::aes(label = sprintf("Pico %s: %s", format_week(.data$source_week), format_count(.data$published_case_count)), vjust = .data$.label_vjust),
      colour = "#173042", fill = "white", linewidth = 0.2, size = 4.0,
      show.legend = FALSE
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$province_name), ncol = 1L, scales = "fixed") +
    ggplot2::scale_x_continuous(breaks = c(1, 12, 26, 39, 52), labels = format_week, limits = c(1, 52)) +
    ggplot2::scale_y_continuous(labels = format_count, limits = c(0, NA), expand = ggplot2::expansion(mult = c(0, 0.18))) +
    ggplot2::labs(
      title = "Dengue 2024: dinámica semanal de las cinco principales jurisdicciones",
      subtitle = "Máximos entre W12 y W14; Córdoba alcanza su pico en W14",
      x = "Semana epidemiológica fuente", y = "Conteos publicados",
      caption = "Primary scope 2024. Cada línea une solo semanas consecutivas con filas publicadas; una ausencia no equivale a cero."
    ) +
    portfolio_theme()
}

#' Build the source age-group composition figure without recoding labels.
#'
#' @param age_group_summary Validated source-age-group summary table.
#' @param total_cases Full-scope published-count total.
#' @return ggplot object.
build_age_group_plot <- function(age_group_summary, total_cases) {
  age_groups <- age_group_summary |>
    dplyr::arrange(.data$.age_group_order, .data$source_age_group_label) |>
    dplyr::mutate(
      source_age_group_label = factor(.data$source_age_group_label, levels = rev(.data$source_age_group_label)),
      .fill_group = ifelse(as.character(.data$source_age_group_label) == "Sin Especificar", "unspecified", "specified")
    )
  top_three <- age_group_summary |>
    dplyr::arrange(dplyr::desc(.data$published_case_count), .data$.age_group_order) |>
    dplyr::slice_head(n = 3L)
  top_three_share <- 100 * sum(top_three$published_case_count) / total_cases
  ggplot2::ggplot(age_groups, ggplot2::aes(x = .data$source_age_group_label, y = .data$published_case_count, fill = .data$.fill_group)) +
    ggplot2::geom_col(width = 0.72) +
    ggplot2::geom_text(ggplot2::aes(label = format_count(.data$published_case_count)), hjust = -0.12, size = 4.5, colour = "#173042") +
    ggplot2::coord_flip(clip = "off") +
    ggplot2::scale_fill_manual(values = c(specified = main_colour, unspecified = unspecified_colour), guide = "none") +
    ggplot2::scale_y_continuous(labels = format_count, limits = c(0, NA), expand = ggplot2::expansion(mult = c(0, 0.13))) +
    ggplot2::labs(
      title = "Dengue 2024: composición por categoría etaria reportada",
      subtitle = sprintf("Las tres categorías fuente entre 25 y 65 años concentran %.2f %% de los conteos publicados", top_three_share),
      x = NULL, y = "Conteos publicados",
      caption = "Primary scope 2024. Etiquetas fuente preservadas; la composición no representa riesgo por edad."
    ) +
    portfolio_theme() +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
}

#' Render one plot to a controlled PNG temporary with deterministic dimensions.
#'
#' @param plot ggplot object.
#' @param path Controlled temporary PNG path.
#' @param dimensions Named integer vector containing width and height in pixels.
#' @param resolution_dpi PNG resolution in dots per inch.
#' @return Invisibly TRUE on success.
render_png <- function(plot, path, dimensions, resolution_dpi) {
  device_open <- FALSE
  tryCatch(
    {
      grDevices::png(filename = path, width = dimensions[["width"]], height = dimensions[["height"]], units = "px", res = resolution_dpi, type = "cairo")
      device_open <- TRUE
      on.exit(if (device_open) grDevices::dev.off(), add = TRUE)
      print(plot)
      grDevices::dev.off()
      device_open <- FALSE
    },
    error = function(error) abort_visualization(sprintf("Could not render PNG figure: %s", error$message))
  )
  invisible(TRUE)
}

#' Render every figure to controlled temporaries before publication.
#'
#' @param plots Named list of ggplot objects.
#' @param output_paths Named list of final figure paths.
#' @param resolution_dpi PNG resolution in dots per inch.
#' @return Named character vector of temporary paths.
render_figure_temporaries <- function(plots, output_paths, resolution_dpi) {
  temporary_paths <- purrr::imap_chr(output_paths, function(path, figure_name) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    tempfile(paste0(".argentina_dengue_", figure_name, "_"), dirname(path), ".png")
  })
  purrr::iwalk(plots, function(plot, figure_name) {
    render_png(plot, temporary_paths[[figure_name]], figure_dimensions[[figure_name]], resolution_dpi)
  })
  temporary_paths
}

#' Atomically publish each already-rendered final portfolio figure.
#'
#' @param temporary_paths Named temporary paths.
#' @param output_paths Named final paths.
#' @return Invisibly TRUE on success.
publish_figures <- function(temporary_paths, output_paths) {
  purrr::iwalk(output_paths, function(path, figure_name) {
    if (!file.rename(temporary_paths[[figure_name]], path)) {
      abort_visualization(sprintf("Could not atomically publish portfolio figure: %s", figure_name))
    }
  })
  invisible(TRUE)
}

#' Run C.10 descriptive portfolio visualization from the project root.
#'
#' @return Invisibly TRUE on success.
main <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    abort_visualization("Required direct dependency ggplot2 is not available.")
  }
  settings <- visualization_config(read_project_config())
  tables <- list(
    weekly_national = read_analysis_table(settings$weekly_national_path, "weekly_national"),
    province_summary = read_analysis_table(settings$province_summary_path, "province_summary"),
    weekly_province = read_analysis_table(settings$weekly_province_path, "weekly_province"),
    age_group_summary = read_analysis_table(settings$age_group_summary_path, "age_group_summary")
  )
  provenance <- validate_analysis_tables(tables)
  validate_province_categories(tables$province_summary, tables$weekly_province)
  plots <- list(
    weekly_national = build_weekly_national_plot(tables$weekly_national),
    province_ranking = build_province_ranking_plot(tables$province_summary, provenance$total_cases),
    top5_provinces_weekly = build_top_provinces_weekly_plot(tables$province_summary, tables$weekly_province),
    age_group_composition = build_age_group_plot(tables$age_group_summary, provenance$total_cases)
  )
  output_paths <- list(
    weekly_national = settings$weekly_national_figure_path,
    province_ranking = settings$province_ranking_figure_path,
    top5_provinces_weekly = settings$top5_provinces_weekly_figure_path,
    age_group_composition = settings$age_group_composition_figure_path
  )
  temporary_paths <- render_figure_temporaries(plots, output_paths, settings$resolution_dpi)
  on.exit(unlink(temporary_paths), add = TRUE)
  publish_figures(temporary_paths, output_paths)
  message(sprintf("scope_id=%s | source_resource_id=%s | source_year=%s | published_rows=%s | published_case_count=%s | weekly=%s | provinces=%s | province_weeks=%s | age_groups=%s", provenance$scope, provenance$resource, provenance$year, provenance$total_rows, provenance$total_cases, nrow(tables$weekly_national), nrow(tables$province_summary), nrow(tables$weekly_province), nrow(tables$age_group_summary)))
  invisible(TRUE)
}

if (length(commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")]) == 1L && basename(sub("^--file=", "", commandArgs(FALSE)[startsWith(commandArgs(FALSE), "--file=")])) == "08_generate_figures.R") {
  main()
}
