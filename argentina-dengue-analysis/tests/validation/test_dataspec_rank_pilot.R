# Regression checks for the retrospective DataSpec rank pilot.
# Inputs: governed project config, preserved pilot audit, existing read-only assets.
# Outputs: console assertions; malformed variants exist only in memory or temp files.

config <- yaml::read_yaml("config/project.yml")
policy <- config$dataspec_rank_pilot
source(policy$audit_script)
paths <- lapply(policy$output_names, function(name) file.path(policy$audit_directory, name))
baseline <- jsonlite::fromJSON(paths$baseline, simplifyVector = FALSE)

# Assert a rejected operation includes the expected reason.
expect_failure <- function(action, expected) {
  error <- tryCatch({ action(); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(expected, conditionMessage(error), fixed = TRUE))
}

# Reject failed audit checks without publishing anything.
require_check <- function(id, passed, detail) {
  if (!isTRUE(passed)) stop(id)
}

bytes <- charToRaw("Synthetic image bytes; no real PNG is needed for extraction testing.")
encoded <- jsonlite::base64_enc(bytes)
html <- paste0(strrep(" ", 1000100L), '<section id="', policy$report_section_id,
               '"><p>Selected scope</p><img src="data:image/png;base64,', encoded,
               '"></section><section id="next">Excluded</section>')
section <- pilot_report_section(html, policy)
stopifnot(grepl("Selected scope", section$text), !grepl("Excluded", section$text),
          identical(section$image_sha256, unclass(as.character(openssl::sha256(bytes)))))
cat("PASS large HTML extraction preserves exact image bytes and section boundaries\n")
expect_failure(function() pilot_report_section("<p>No section</p>", policy), "section is absent")
expect_failure(function() pilot_report_section(paste0('<section id="', policy$report_section_id, '">'), policy), "section is unclosed")
cat("PASS absent and truncated report sections are rejected\n")

altered <- config
altered$published_count_rate$scenarios$contemporary[["2024"]] <- "invented_vintage"
expect_failure(function() pilot_check_baseline(baseline, paths$baseline_config, altered), "identical(previous, current)")
cat("PASS unrelated analytical configuration changes are rejected\n")

wrong_count <- policy
wrong_count$expected_province_count <- 23L
expect_failure(function() pilot_rank_checks(config, wrong_count, tempdir(), require_check), "province_grain")
cat("PASS incorrect province cardinality is rejected before reproduction\n")

metadata <- list.files(policy$audit_directory, full.names = TRUE)
before <- vapply(metadata, pilot_sha256, "")
stdout <- tempfile(); stderr <- tempfile()
status <- system2(file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(policy$audit_script), shQuote(paths$baseline), shQuote(paths$baseline_config)),
  stdout = stdout, stderr = stderr)
stopifnot(status != 0L, any(grepl("refuse overwrite", readLines(stderr), fixed = TRUE)))
status <- system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", shQuote(policy$trace_script)),
                  stdout = stdout, stderr = stderr)
stopifnot(status != 0L, any(grepl("refuse overwrite", readLines(stderr), fixed = TRUE)),
          identical(before, vapply(metadata, pilot_sha256, "")))
unlink(c(stdout, stderr))
cat("PASS both producers refuse overwriting existing provenance\n")

integrity <- pilot_check_baseline(baseline, paths$baseline_config, config)
stopifnot(integrity$all_original_bytes_preserved)
cat("PASS all protected original files remain intact\n")
