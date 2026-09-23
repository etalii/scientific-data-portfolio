# Regression checks for human-authorized DataSpec rank closure.
# Inputs: immutable accepted snapshot, explicit decisions and historical evidence.
# Outputs: console assertions; all fault injection stays in memory.

config <- yaml::read_yaml("config/project.yml")
policy <- config$dataspec_rank_pilot
closure <- policy$closure
source(policy$audit_script)
source(closure$producer)
core <- new.env(parent = globalenv())
sys.source(policy$framework_core, envir = core)
schema <- normalizePath(policy$framework_schema)
bundle <- core$read_json_strict(file.path(closure$directory, policy$output_names$bundle))
decisions <- yaml::read_yaml(closure$decisions)
fragment <- closure_text(file.path(closure$directory, closure$fragment_name))

# Require a failure without relaxing the original error condition.
expect_failure <- function(action) {
  error <- tryCatch({ action(); NULL }, error = identity)
  stopifnot(inherits(error, "error"))
}

bad <- decisions
bad$items[[6]]$human_disposition <- "ACCEPT"
expect_failure(function() closure_check_edits(config, bad, fragment))
bad <- decisions
bad$approved_introduction <- "Population adjustment proves disease risk."
expect_failure(function() closure_check_edits(config, bad, fragment))
expect_failure(function() closure_replace_once("duplicate duplicate", "duplicate", "replacement"))
cat("PASS altered human disposition, unauthorized prose and ambiguous replacement rejected\n")

closure_negative_checks(bundle, config, core, schema)
cat("PASS automated-only review cannot accept delivery; changed evidence stales delivery\n")

original <- core$read_json_strict(file.path(policy$audit_directory, policy$output_names$bundle))
records <- setNames(bundle$records, vapply(bundle$records, `[[`, "", "artifact_id"))
old <- setNames(original$records, vapply(original$records, `[[`, "", "artifact_id"))
unchanged <- c("question", "plan", "contract_c16", "contract_c20", "contract_pilot", "metric_count", "metric_rate")
stopifnot(identical(records[unchanged], old[unchanged]))
for (id in names(old)[vapply(old, function(x) x$kind == "claim", logical(1))]) {
  stopifnot(identical(records[[id]]$payload$claim_text, old[[id]]$payload$claim_text),
            identical(records[[id]]$payload$scope, old[[id]]$payload$scope))
}
stopifnot(identical(records$visual$payload$labels$caption, decisions$approved_caption),
          identical(records$visual$payload$labels$alt_text, decisions$approved_alt_text),
          identical(records$narrative$payload$ordered_sections[[1]]$text, decisions$approved_introduction))
visual <- new.env(parent = globalenv())
sys.source(policy$visualization_producer, envir = visual)
stopifnot(identical(gsub("\n", " ", visual$localized_strings(policy$figure_language)$rate_caption, fixed = TRUE), decisions$approved_caption))
cat("PASS historical core records and claim values unchanged; exact approved specs match PNG caption\n")

files <- list.files(closure$directory, full.names = TRUE)
before <- vapply(files, pilot_sha256, "")
stdout <- tempfile(); stderr <- tempfile()
status <- suppressWarnings(system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", shQuote(closure$producer)), stdout = stdout, stderr = stderr))
stopifnot(status != 0L, any(grepl("refuse overwrite", readLines(stderr), fixed = TRUE)), identical(before, vapply(files, pilot_sha256, "")))
unlink(c(stdout, stderr))
cat("PASS closure producer refuses overwrite and preserves every published byte\n")
