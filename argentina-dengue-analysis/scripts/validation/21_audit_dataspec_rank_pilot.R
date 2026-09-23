# Retrospective DataSpec rank audit.
# Inputs: config/project.yml, captured baseline/configuration, governed C.16 inputs.
# Outputs: immutable audit provenance; reproduction runs only in temporary storage.

# Return the SHA-256 identity of existing bytes without altering the file.
pilot_sha256 <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  unclass(as.character(openssl::sha256(connection)))
}

# Format the actual time of this audit in UTC.
pilot_time <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

# Serialize provenance consistently; publication is handled by the owning bundle.
pilot_write_json <- function(value, path) {
  text <- jsonlite::toJSON(value, auto_unbox = TRUE, null = "null", pretty = TRUE, digits = NA)
  writeLines(text, path, useBytes = TRUE)
}

# Preserve identifiers as text, including leading zeroes.
pilot_read_table <- function(path) {
  utils::read.csv(path, colClasses = "character", check.names = FALSE,
                 stringsAsFactors = FALSE, encoding = "UTF-8")
}

# Execute a producer in an isolated working directory and restore the caller's root.
pilot_run_isolated <- function(directory, script) {
  original <- getwd()
  on.exit(setwd(original), add = TRUE)
  setwd(directory)
  output <- system2(file.path(R.home("bin"), "Rscript"),
                    c("--vanilla", shQuote(script)), stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  list(exit_code = if (is.null(status)) 0L else as.integer(status), output = as.list(output))
}

# Reproduce C.16 from copied governed inputs, retaining only comparison metadata.
pilot_reproduce_rates <- function(config, policy, baseline_config, root, scratch) {
  dir.create(file.path(scratch, "config"), recursive = TRUE)
  stopifnot(file.copy(baseline_config, file.path(scratch, "config/project.yml")))
  for (key in policy$c16_input_keys) {
    relative <- config$artifacts[[key]]
    destination <- file.path(scratch, relative)
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(file.path(root, relative), destination))
  }
  run <- pilot_run_isolated(scratch, file.path(root, policy$rate_producer))
  if (run$exit_code != 0L) stop(paste(unlist(run$output), collapse = "\n"))
  comparisons <- lapply(policy$c16_output_keys, function(key) {
    relative <- config$artifacts[[key]]
    original <- pilot_sha256(file.path(root, relative))
    reproduced <- pilot_sha256(file.path(scratch, relative))
    list(artifact_key = key, path = relative, original_sha256 = original,
         reproduced_sha256 = reproduced, identical_bytes = identical(original, reproduced))
  })
  list(run = run, comparisons = comparisons)
}

# Extract the selected report section and the exact bytes of its embedded PNG.
pilot_report_section <- function(html, policy) {
  marker <- sprintf('<section id="%s"', policy$report_section_id)
  begin <- regexpr(marker, html, fixed = TRUE)[[1]]
  if (begin < 1L) stop("Selected report section is absent")
  rest <- substring(html, begin, nchar(html))
  end <- regexpr("</section>", rest, fixed = TRUE)[[1]]
  if (end < 1L) stop("Selected report section is unclosed")
  section <- substr(rest, 1L, end + nchar("</section>") - 1L)
  image_match <- regmatches(section, regexec('src="data:image/png;base64,([^\"]+)"', section, perl = TRUE))[[1]]
  if (length(image_match) != 2L) stop("Selected section lacks its embedded PNG")
  list(text = gsub("[[:space:]]+", " ", gsub("<[^>]+>", " ", section)),
       image_sha256 = unclass(as.character(openssl::sha256(jsonlite::base64_dec(image_match[[2]])))))
}

# Assert original identities and the limited additive configuration change.
pilot_check_baseline <- function(baseline, baseline_config, config) {
  previous <- yaml::read_yaml(baseline_config)
  current <- config
  current$dataspec_rank_pilot <- NULL
  stopifnot(identical(previous, current))
  unchanged <- vapply(baseline$files, function(entry) {
    path <- if (entry$path == "config/project.yml") baseline_config else entry$path
    identical(pilot_sha256(path), entry$sha256)
  }, logical(1))
  stopifnot(all(unchanged))
  list(protected_file_count = length(unchanged), all_original_bytes_preserved = TRUE,
       permitted_change = "Additive dataspec_rank_pilot configuration only",
       original_config_sha256 = pilot_sha256(baseline_config),
       extended_config_sha256 = pilot_sha256("config/project.yml"))
}

# Reconcile measures, ranks, published prose, and an isolated figure rerender.
pilot_rank_checks <- function(config, policy, scratch, add_check) {
  display <- config$epidemiological_portfolio_visualization
  table <- pilot_read_table(config$artifacts$epidemiology_province_summary)
  selected <- table[table$analysis_scope_id == display$calendar_year_scope_id &
                      table$denominator_scenario == display$rate_denominator_scenario, ]
  add_check("province_grain", nrow(selected) == policy$expected_province_count &&
              !anyDuplicated(selected$reference_province_id), "Exactly 24 unique mapped provinces")
  vintage <- config$published_count_rate$scenarios[[display$rate_denominator_scenario]][[as.character(display$calendar_year)]]
  date <- paste(display$calendar_year, policy$expected_population_month_day, sep = "-")
  add_check("scope_and_denominator", all(selected$source_year == display$calendar_year) &&
              all(selected$projection_vintage == vintage) && all(selected$population_reference_date == date) &&
              all(selected$rate_period_basis == "observed_weeks_01_52"),
            "Calendar year, contemporary vintage, July 1 reference, observed W01-W52")
  for (field in c("published_case_count", "province_population", "published_count_rate_100k")) {
    selected[[field]] <- as.numeric(selected[[field]])
  }
  measures <- as.matrix(selected[c("published_case_count", "province_population", "published_count_rate_100k")])
  add_check("finite_measures", all(is.finite(measures)) && all(selected$published_case_count >= 0) &&
              all(selected$province_population > 0), "Nonnegative counts and positive denominators")
  population <- pilot_read_table(config$artifacts$population_denominators)
  population <- population[population$geography_level == "province" &
                             population$population_year == display$calendar_year &
                             population$projection_vintage == vintage, ]
  index <- match(selected$reference_province_id, population$province_reference_id)
  add_check("population_reference", !anyNA(index) && !anyDuplicated(population$province_reference_id) &&
              all(selected$province_population == as.numeric(population$population[index])),
            "All 24 denominators match C.14 by province/year/vintage")
  recomputed <- policy$rate_multiplier * selected$published_case_count / selected$province_population
  add_check("rate_formula", all(abs(recomputed - selected$published_count_rate_100k) <= policy$numeric_tolerance),
            "All rates reconcile to count/population times 100000")
  mapping <- pilot_read_table(config$artifacts$geographic_mapping_validation_snapshot)
  mapping <- mapping[mapping$analysis_scope_id == display$calendar_year_scope_id, ]
  add_check("geographic_eligibility", nrow(mapping) == 1L &&
              mapping$rate_geography_eligibility_status == "supported_with_caveats" &&
              sum(selected$published_case_count) == as.numeric(mapping$mapped_published_case_count),
            "Mapped totals reconcile to C.15; nonassignable geography is not redistributed")
  selected$count_rank <- match(seq_len(nrow(selected)), order(-selected$published_case_count, selected$reference_province_id, method = "radix"))
  selected$rate_rank <- match(seq_len(nrow(selected)), order(-selected$published_count_rate_100k, selected$reference_province_id, method = "radix"))
  featured <- lapply(display$featured_provinces, function(expected) {
    row <- selected[selected$reference_province_id == expected$reference_province_id, ]
    add_check(paste0("rank_", expected$reference_province_id), nrow(row) == 1L &&
                row$count_rank == expected$count_rank && row$rate_rank == expected$rate_rank,
              sprintf("%s: %s to %s", row$reference_province_name, row$count_rank, row$rate_rank))
    list(reference_province_id = row$reference_province_id, reference_province_name = row$reference_province_name,
         expected_count_rank = expected$count_rank, observed_count_rank = row$count_rank,
         expected_rate_rank = expected$rate_rank, observed_rate_rank = row$rate_rank)
  })
  visual <- new.env(parent = globalenv())
  sys.source(policy$visualization_producer, envir = visual)
  reproduced_ranks <- visual$rank_measure(selected, "published_case_count", "count_rank") |>
    visual$rank_measure("published_count_rate_100k", "rate_rank")
  rank_index <- match(selected$reference_province_id, reproduced_ranks$reference_province_id)
  add_check("c20_rank_implementation", identical(selected$count_rank, reproduced_ranks$count_rank[rank_index]) &&
              identical(selected$rate_rank, reproduced_ranks$rate_rank[rank_index]),
            "Independent ordering equals the existing C.20 rank function")
  settings <- visual$visualization_settings(config, policy$figure_language)
  figure_key <- "province_count_rate_rank_shift_2024"
  original_figure <- settings$outputs[[figure_key]]
  candidate_figure <- file.path(scratch, "rank_reproduction.png")
  plot <- visual$build_province_rank_plot(reproduced_ranks, settings)
  visual$render_png(plot, candidate_figure, visual$figure_dimensions[[figure_key]], settings$dpi)
  visual$validate_png(original_figure, visual$figure_dimensions[[figure_key]])
  visual$validate_png(candidate_figure, visual$figure_dimensions[[figure_key]])
  png_comparison <- list(path = original_figure, original_sha256 = pilot_sha256(original_figure),
                         reproduced_sha256 = pilot_sha256(candidate_figure))
  add_check("c20_png_reproduction", identical(png_comparison$original_sha256, png_comparison$reproduced_sha256),
            "Selected English figure reproduces byte-for-byte in isolation")
  html <- paste(readLines(config$artifacts$argentina_dengue_portfolio_report_html, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  section <- pilot_report_section(html, policy)
  for (item in featured) {
    text <- sprintf("%s: count rank %s to rate rank %s.", item$reference_province_name,
                    item$observed_count_rank, item$observed_rate_rank)
    add_check(paste0("report_", item$reference_province_id), grepl(text, section$text, fixed = TRUE),
              "Rendered statement agrees with computed rank")
  }
  add_check("report_embedded_figure", identical(section$image_sha256, png_comparison$original_sha256),
            "Selected report image is byte-identical to the governed PNG")
  add_check("report_scope_and_geography", grepl(sprintf("Calendar year %s", display$calendar_year), section$text, fixed = TRUE) &&
              grepl("contemporary denominator scenario", section$text, fixed = TRUE) &&
              grepl("unknown or nonassignable geography is not redistributed", section$text, fixed = TRUE),
            "Rendered section states the period/scenario and geographic caveat")
  source <- paste(readLines(policy$report_source, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  add_check("report_source_link", grepl(policy$figure_id, source, fixed = TRUE) &&
              grepl("featured_value", source, fixed = TRUE) &&
              grepl("does not estimate unique people, incidence, individual risk", source, fixed = TRUE),
            "Quarto source links dynamic ranks, figure, and interpretation limits")
  list(featured = featured, png = png_comparison,
       scope = list(analysis_scope_id = display$calendar_year_scope_id,
                    source_year = as.integer(display$calendar_year), denominator_scenario = display$rate_denominator_scenario,
                    projection_vintage = vintage, population_reference_date = date,
                    geography = "24 mapped INDEC jurisdictions", rate_period_basis = "observed_weeks_01_52"))
}

# Audit the chain and atomically publish only new provenance metadata.
main <- function() {
  arguments <- commandArgs(trailingOnly = TRUE)
  if (length(arguments) != 2L) stop("Usage: Rscript --vanilla 21_audit_dataspec_rank_pilot.R BASELINE_JSON BASELINE_CONFIG")
  root <- normalizePath(".")
  config <- yaml::read_yaml("config/project.yml")
  policy <- config$dataspec_rank_pilot
  if (is.null(policy)) stop("Missing dataspec_rank_pilot configuration")
  if (dir.exists(policy$audit_directory)) stop("Audit directory already exists; refuse overwrite")
  baseline_path <- normalizePath(arguments[[1]], mustWork = TRUE)
  baseline_config <- normalizePath(arguments[[2]], mustWork = TRUE)
  baseline <- jsonlite::fromJSON(baseline_path, simplifyVector = FALSE)
  if (nzchar(baseline$project_tracked_diff)) stop("Captured baseline had tracked project differences")
  started <- pilot_time()
  scratch <- tempfile("dataspec_dengue_reproduction_")
  dir.create(scratch)
  on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
  checks <- list()
  add_check <- function(id, passed, detail) {
    if (!isTRUE(passed)) stop(sprintf("Pilot check failed [%s]: %s", id, detail))
    checks[[length(checks) + 1L]] <<- list(check_id = id, status = "pass", detail = detail)
  }
  integrity_before <- pilot_check_baseline(baseline, baseline_config, config)
  reproduction <- pilot_reproduce_rates(config, policy, baseline_config, root, scratch)
  add_check("c16_reproduction", all(vapply(reproduction$comparisons, `[[`, logical(1), "identical_bytes")),
            "All six C.16 outputs reproduce byte-for-byte from governed inputs")
  rank_audit <- pilot_rank_checks(config, policy, scratch, add_check)
  integrity_after <- pilot_check_baseline(baseline, baseline_config, config)
  add_check("baseline_integrity", identical(integrity_before, integrity_after),
            sprintf("All %s original identities preserved; only additive configuration permitted", length(baseline$files)))
  package_names <- c("yaml", "jsonlite", "openssl", "readr", "dplyr", "ggplot2", "purrr", "tibble")
  environment <- list(r_version = R.version.string, platform = R.version$platform,
    packages = setNames(lapply(package_names, function(p) as.character(utils::packageVersion(p))), package_names),
    baseline_git_commit = baseline$baseline_git_commit, audit_script_sha256 = pilot_sha256(policy$audit_script),
    framework_core_sha256 = pilot_sha256(policy$framework_core), environment_lock_sha256 = pilot_sha256(policy$environment_lock))
  inputs <- lapply(policy$c16_input_keys, function(key) list(artifact_key = key, path = config$artifacts[[key]], sha256 = pilot_sha256(config$artifacts[[key]])))
  audit <- list(contract_id = "dataspec_rank_pilot", contract_version = "1.0.0",
    started_at = started, finished_at = pilot_time(), command = as.list(c("Rscript", "--vanilla", policy$audit_script, arguments)),
    baseline_git_commit = baseline$baseline_git_commit, scope = rank_audit$scope, inputs = inputs,
    c16_reproduction = reproduction, featured_rank_checks = rank_audit$featured, png_reproduction = rank_audit$png,
    integrity = integrity_after, reproduction_status = "passed",
    historical_gaps = list("Original C.16/C.20 execution timestamps and human-review attestations were not recovered; this is a new isolated reproduction.",
                           "No upstream acquisition, source completeness, epidemiological incidence, or whole-report certification is asserted."))
  parent <- dirname(policy$audit_directory)
  dir.create(parent, recursive = TRUE, showWarnings = FALSE)
  staging <- tempfile(".dataspec_rank_pilot_", parent)
  dir.create(staging)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  names <- policy$output_names
  stopifnot(file.copy(baseline_path, file.path(staging, names$baseline)),
            file.copy(baseline_config, file.path(staging, names$baseline_config)))
  pilot_write_json(environment, file.path(staging, names$environment))
  pilot_write_json(checks, file.path(staging, names$checks))
  pilot_write_json(audit, file.path(staging, names$audit))
  if (!file.rename(staging, policy$audit_directory)) stop("Atomic audit publication failed")
  message(sprintf("Audit passed: %s checks; six C.16 outputs and selected PNG match baseline.", length(checks)))
}

if (sys.nframe() == 0L) main()
