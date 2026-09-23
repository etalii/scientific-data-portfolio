# Apply explicit human dispositions to the retrospective rank pilot.
# Inputs: configured decisions, preserved v1 provenance and governed inputs.
# Outputs: immutable accepted snapshot and fragment; --check is read-only.

# Read UTF-8 without truncating large embedded images.
closure_text <- function(path) paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

# Reject ambiguous replacements instead of editing another passage.
closure_replace_once <- function(text, old, new) {
  locations <- gregexpr(old, text, fixed = TRUE)[[1]]
  if (length(locations) != 1L || locations[[1]] < 1L) stop("Expected exactly one approved editorial source occurrence")
  sub(old, new, text, fixed = TRUE)
}

# Escape authored caveats for literal HTML presentation.
closure_escape <- function(text) {
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  gsub(">", "&gt;", text, fixed = TRUE)
}

# Canonically revise only the archived selected section, without Quarto rendering.
closure_fragment <- function(config, decisions) {
  policy <- config$dataspec_rank_pilot
  html <- closure_text(config$artifacts$argentina_dengue_portfolio_report_html)
  start <- regexpr(paste0('<section id="', policy$report_section_id, '"'), html, fixed = TRUE)[[1]]
  if (start < 1L) stop("Archived section missing")
  section <- substring(html, start, nchar(html))
  end <- regexpr("</section>", section, fixed = TRUE)[[1]]
  if (end < 1L) stop("Archived section unclosed")
  section <- substr(section, 1L, end + nchar("</section>") - 1L)
  section <- closure_replace_once(section, decisions$previous_introduction, decisions$approved_introduction)
  for (attribute in c("alt", "aria-label")) {
    section <- closure_replace_once(section,
      paste0(attribute, '="', decisions$previous_alt_text, '"'),
      paste0(attribute, '="', decisions$approved_alt_text, '"'))
  }
  caveats <- paste0("<li>", closure_escape(unlist(decisions$limitations)), "</li>", collapse = "\n")
  section <- closure_replace_once(section, "</section>", paste0('<aside aria-label="Accepted pilot limitations"><h3>Accepted retrospective pilot limitations</h3><ul>', caveats, "</ul></aside></section>"))
  paste0('<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Accepted retrospective dengue rank pilot</title><style>body{font-family:sans-serif;max-width:1100px;margin:2rem auto;padding:0 1rem;line-height:1.5}img{max-width:100%;height:auto}td,th{padding:.35rem;text-align:left}aside{border-top:1px solid #ccc;margin-top:2rem}</style></head><body><main>\n', section, '\n</main></body></html>')
}

# Verify the nine source dispositions and literal implemented edits.
closure_check_edits <- function(config, decisions, fragment) {
  closure <- config$dataspec_rank_pilot$closure
  source <- closure_text(closure$report_source)
  request <- closure_text(closure$request)
  expected <- c(rep("ACCEPT", 5L), "ACCEPT WITH EDIT", "ACCEPT", "ACCEPT WITH EDIT", "ACCEPT")
  stopifnot(identical(vapply(decisions$items, `[[`, "", "item_id"), sprintf("H%02d", 1:9)),
            identical(vapply(decisions$items, `[[`, "", "human_disposition"), expected))
  for (text in unlist(decisions[c("approved_introduction", "approved_alt_text", "approved_caption")])) stopifnot(grepl(text, request, fixed = TRUE))
  for (text in unlist(decisions[c("approved_introduction", "approved_alt_text")])) {
    stopifnot(grepl(text, source, fixed = TRUE), grepl(text, fragment, fixed = TRUE))
  }
  stopifnot(!grepl("24 Argentine provinces", source, fixed = TRUE), !grepl("24 Argentine provinces", fragment, fixed = TRUE))
  for (text in unlist(decisions$limitations)) stopifnot(grepl(text, source, fixed = TRUE), grepl(closure_escape(text), fragment, fixed = TRUE))
  TRUE
}

# Copy protected and explicitly referenced inputs into a private staging root.
closure_stage_inputs <- function(config, root, stage, baseline, old_bundle, core) {
  policy <- config$dataspec_rank_pilot
  files <- unique(c(vapply(baseline$files, `[[`, "", "path"),
    vapply(core$collect_refs(old_bundle, "external"), function(x) x$value$path, ""),
    list.files(policy$audit_directory, full.names = TRUE), policy$trace_script,
    unlist(policy$closure[c("producer", "contract", "decisions", "request", "previous_config", "report_source")])))
  for (relative in files) {
    target <- file.path(stage, relative)
    dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(file.path(root, relative), target))
  }
}

# Run the original 21 controls against the approved presentation in isolation.
closure_audit <- function(config, baseline, historical_config, fragment_path) {
  policy <- config$dataspec_rank_pilot
  scratch <- tempfile("rank_closure_reproduction_")
  dir.create(scratch)
  on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
  checks <- list()
  add_check <- function(id, passed, detail) {
    if (!isTRUE(passed)) stop(sprintf("Closure check failed [%s]: %s", id, detail))
    checks[[length(checks) + 1L]] <<- list(check_id = id, status = "pass", detail = detail)
  }
  started <- pilot_time()
  before <- pilot_check_baseline(baseline, historical_config, config)
  rates <- pilot_reproduce_rates(config, policy, historical_config, normalizePath("."), scratch)
  add_check("c16_reproduction", all(vapply(rates$comparisons, `[[`, logical(1), "identical_bytes")), "All six C.16 outputs reproduce byte-for-byte from governed inputs")
  final_config <- config
  final_config$artifacts$argentina_dengue_portfolio_report_html <- fragment_path
  final_policy <- policy
  final_policy$report_source <- policy$closure$report_source
  ranks <- pilot_rank_checks(final_config, final_policy, scratch, add_check)
  after <- pilot_check_baseline(baseline, historical_config, config)
  add_check("baseline_integrity", identical(before, after), sprintf("All %s original identities preserved; only additive configuration permitted", length(baseline$files)))
  list(audit = list(contract_id = "dataspec_rank_closure", contract_version = "1.0.0",
    started_at = started, finished_at = pilot_time(), command = as.list(c("Rscript", "--vanilla", policy$closure$producer)),
    baseline_git_commit = baseline$baseline_git_commit, scope = ranks$scope,
    inputs = lapply(policy$c16_input_keys, function(key) list(artifact_key = key, path = config$artifacts[[key]], sha256 = pilot_sha256(config$artifacts[[key]]))),
    c16_reproduction = rates, featured_rank_checks = ranks$featured, png_reproduction = ranks$png,
    integrity = after, reproduction_status = "passed",
    historical_gaps = list("Original C.16/C.20 execution timestamps and human-review attestations were not recovered; this is a new isolated reproduction.",
      "No upstream acquisition, source completeness, epidemiological incidence, or whole-report certification is asserted.")), checks = checks)
}

# Build the accepted candidate snapshot without rewriting earlier identities.
closure_bundle <- function(config, audit, environment, old_bundle, decisions) {
  policy <- config$dataspec_rank_pilot
  closure <- policy$closure
  current <- config
  current$dataspec_rank_pilot$audit_directory <- closure$directory
  current$dataspec_rank_pilot$revision <- 2L
  fragment <- file.path(closure$directory, closure$fragment_name)
  current$artifacts$argentina_dengue_portfolio_report_html <- fragment
  bundle <- build_rank_records(current, audit, environment)
  unchanged <- c("question", "plan", "contract_c16", "contract_c20", "contract_pilot", "metric_count", "metric_rate")
  # Select unchanged revision 1 and changed revision 2 throughout references.
  revise_refs <- function(value) {
    if (!is.list(value)) return(value)
    if (all(c("project_id", "artifact_id", "revision") %in% names(value))) {
      if (value$artifact_id == "review_automated") value$artifact_id <- closure$automated_review_id
      value$revision <- if (value$artifact_id %in% unchanged || value$artifact_id == closure$automated_review_id) 1L else 2L
    }
    lapply(value, revise_refs)
  }
  bundle <- revise_refs(bundle)
  records <- setNames(bundle$records, vapply(bundle$records, `[[`, "", "artifact_id"))
  originals <- setNames(old_bundle$records, vapply(old_bundle$records, `[[`, "", "artifact_id"))
  records[unchanged] <- originals[unchanged]
  external <- function(path, locator) list(path = path, sha256 = pilot_sha256(path), locator = locator, availability = "verified_local")
  sort_external <- function(values) values[order(vapply(values, function(x) paste(x$path, x$sha256, x$locator, sep = "\t"), ""), method = "radix")]
  ref <- function(id) list(project_id = policy$project_id, artifact_id = id, revision = records[[id]]$revision)
  refs <- function(ids) lapply(sort(unique(ids), method = "radix"), ref)
  historical_bundle <- file.path(policy$audit_directory, policy$output_names$bundle)
  decision_refs <- sort_external(list(external(closure$decisions, "H01-H09, exact edits, full limitations and review scopes"),
    external(closure$request, "Explicit user dispositions and conditional closure authorization"),
    external(historical_bundle, "Immutable retrospective revision-1 record history"),
    external(closure$contract, "Identity, lifecycle and bounded acceptance")))
  run <- records$execution_audit$payload
  run$code_refs <- sort_external(c(run$code_refs, list(external(closure$producer, "Canonical editorial revision, audit and closure producer"),
    external(policy$trace_script, "build_rank_records reused for schema-compatible registration"))))
  run$input_refs <- sort_external(c(run$input_refs, decision_refs,
    list(external(closure$report_source, "Authoritative approved narrative and alt text"), external(closure$previous_config, "Exact pre-closure configuration; original bundle replay"))))
  run$output_refs <- sort_external(c(run$output_refs, list(external(fragment, paste0("#", policy$report_section_id)))))
  records$execution_audit$payload <- run
  claim_ids <- names(records)[vapply(records, function(x) x$kind == "claim", logical(1))]
  for (id in c(claim_ids, "narrative", "visual", "delivery")) {
    records[[id]]$status <- "accepted"
    records[[id]]$limitations <- decisions$limitations
  }
  for (id in claim_ids) {
    stopifnot(identical(records[[id]]$payload$claim_text, originals[[id]]$payload$claim_text))
    records[[id]]$payload$caveats <- decisions$limitations
  }
  records$narrative$payload$communication_goal <- "Explain the two descriptive orderings using selected contrasts, without implying temporal change, effect magnitude or disease risk."
  records$narrative$payload$ordered_sections[[1]]$text <- decisions$approved_introduction
  records$narrative$payload$mandatory_caveats <- decisions$limitations
  records$visual$payload$labels$alt_text <- decisions$approved_alt_text
  records$visual$payload$labels$caption <- decisions$approved_caption
  records$visual$payload$render_targets <- list("Unchanged English PNG and its embedded copy in the accepted report fragment")
  records$visual$payload$uncertainty_display <- paste(unlist(decisions$limitations[1:8]), collapse = " ")
  auto <- records[[closure$automated_review_id]]
  auto$payload$checks[[1]]$evidence_refs <- sort_external(list(external(file.path(closure$directory, policy$output_names$checks), "21 canonical post-review controls")))
  auto$payload$checks[[1]]$note <- "Mechanical closure audit passed; human dispositions are recorded separately from the explicit user instruction."
  auto$payload$findings <- list("Approved introduction/alt/caption reconciled; PNG and six indicators unchanged. No whole-report rerender or independent peer review is claimed.")
  records[[closure$automated_review_id]] <- auto
  stamp <- pilot_time()
  review <- function(id, targets, dimensions, checks, findings) list(schema_version = "0.1.0",
    project_id = policy$project_id, study_id = policy$study_id, artifact_id = id, revision = 1L,
    kind = "review", owner = policy$record_owner, created_at = stamp, record_origin = "retrospective",
    status = "accepted", depends_on = list(), limitations = decisions$limitations,
    payload = list(target_refs = refs(targets), reviewer = decisions$reviewer, review_mode = decisions$review_mode,
      review_dimensions = as.list(sort(dimensions, method = "radix")), checks = checks,
      findings = findings, disposition = "pass", reviewed_at = stamp))
  checks <- lapply(decisions$items, function(item) list(check_id = tolower(item$item_id), result = "pass", evidence_refs = decision_refs,
    note = paste(item$human_disposition, "for", item$target, item$dimension,
      if (item$human_disposition == "ACCEPT WITH EDIT") "— exact authorized editorial revision applied before acceptance." else "— accepted within recorded scope and limitations.")))
  records[[closure$human_review_id]] <- review(closure$human_review_id, c(claim_ids, "narrative", "visual"),
    c("scientific", "narrative", "visual", "reproducibility"), checks,
    list(decisions$identity_basis, decisions$review_time_basis, decisions$limitations[[11]], decisions$limitations[[12]]))
  delivery <- records$delivery
  delivery$payload$review_refs <- refs(c(closure$automated_review_id, closure$human_review_id))
  delivery$payload$known_gaps <- decisions$limitations
  delivery$payload$reproduction_instructions <- paste("Run Rscript --vanilla", closure$producer, "--check from the project root. Available ignored analytical inputs and the verified R environment are required; original metadata and report remain immutable.")
  delivery$payload$dependency_snapshot <- refs(setdiff(names(records), "delivery"))
  records$delivery <- delivery
  records[[closure$delivery_review_id]] <- review(closure$delivery_review_id, "delivery", "scientific",
    list(list(check_id = "conditional_delivery_acceptance", result = "pass", evidence_refs = decision_refs,
      note = decisions$conditional_delivery_authorization)),
    list("User-authorized conditional closure applied after technical checks and exact edits; no new scientific claim or independent certification."))
  bundle$records <- unname(records[sort(names(records), method = "radix")])
  bundle$candidate_refs <- refs(names(records))
  bundle
}

# Ensure human review is necessary and evidence changes invalidate delivery.
closure_negative_checks <- function(bundle, config, core, schema) {
  policy <- config$dataspec_rank_pilot
  altered <- bundle
  for (i in seq_along(altered$records)) if (altered$records[[i]]$artifact_id %in% unlist(policy$closure[c("human_review_id", "delivery_review_id")])) altered$records[[i]]$payload$review_mode <- "automated"
  result <- core$validate_bundle(altered, ".", schema)
  stopifnot(!result$valid, any(vapply(result$findings, function(x) x$code == "REVIEW", logical(1))))
  altered <- bundle
  index <- which(vapply(altered$records, function(x) x$artifact_id == "execution_audit", logical(1)))
  altered$records[[index]]$payload$input_refs[[1]]$sha256 <- strrep("0", 64L)
  result <- core$validate_bundle(altered, ".", schema)
  states <- setNames(vapply(result$records, `[[`, "", "readiness"), vapply(result$records, `[[`, "", "identity"))
  stopifnot(!result$valid, states[[sprintf("%s/delivery/%012d", policy$project_id, 2L)]] == "stale")
  list(human_review_required = TRUE, altered_evidence_invalidates_delivery = TRUE, changed_in_memory_only = TRUE)
}

# Build once atomically, or recheck the accepted snapshot without modifying it.
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) && !identical(args, "--check")) stop("Usage: Rscript --vanilla 23_close_dataspec_rank_pilot.R [--check]")
  checking <- identical(args, "--check")
  root <- normalizePath(".")
  config <- yaml::read_yaml("config/project.yml")
  policy <- config$dataspec_rank_pilot
  closure <- policy$closure
  source(policy$audit_script)
  source(policy$trace_script)
  core <- new.env(parent = globalenv())
  sys.source(policy$framework_core, envir = core)
  schema <- normalizePath(policy$framework_schema)
  final <- file.path(root, closure$directory)
  if (!checking && dir.exists(final)) stop("Closure directory already exists; refuse overwrite")
  if (checking && !dir.exists(final)) stop("Accepted closure directory missing")
  baseline <- core$read_json_strict(file.path(policy$audit_directory, policy$output_names$baseline))
  old_bundle <- core$read_json_strict(file.path(policy$audit_directory, policy$output_names$bundle))
  decisions <- yaml::read_yaml(closure$decisions)
  before_files <- if (checking) list.files(final, full.names = TRUE) else character()
  before_hashes <- vapply(before_files, pilot_sha256, "")
  stage <- tempfile(".rank_closure_", dirname(final))
  dir.create(stage, recursive = TRUE)
  stage <- normalizePath(stage)
  on.exit({ setwd(root); unlink(stage, recursive = TRUE) }, add = TRUE)
  closure_stage_inputs(config, root, stage, baseline, old_bundle, core)
  setwd(stage)
  current_config <- readBin("config/project.yml", "raw", n = file.info("config/project.yml")$size)
  stopifnot(file.copy(closure$previous_config, "config/project.yml", overwrite = TRUE))
  original_validation <- core$validate_bundle(old_bundle, ".", schema)
  stopifnot(length(original_validation$findings) == 9L, all(vapply(original_validation$findings, function(x) x$code == "REVIEW", logical(1))))
  writeBin(current_config, "config/project.yml")
  dir.create(closure$directory, recursive = TRUE)
  if (checking) stopifnot(all(file.copy(before_files, closure$directory)))
  fragment_path <- file.path(closure$directory, closure$fragment_name)
  fragment <- closure_fragment(config, decisions)
  closure_check_edits(config, decisions, fragment)
  if (checking) stopifnot(identical(closure_text(fragment_path), fragment)) else writeLines(fragment, fragment_path, useBytes = TRUE)
  baseline_config <- file.path(policy$audit_directory, policy$output_names$baseline_config)
  result <- closure_audit(config, baseline, baseline_config, fragment_path)
  stopifnot(length(result$checks) == 21L)
  if (checking) {
    paths <- lapply(policy$output_names, function(name) file.path(closure$directory, name))
    stopifnot(identical(core$read_json_strict(paths$checks), result$checks))
    bundle <- core$read_json_strict(paths$bundle)
    validation <- core$validate_bundle(bundle, ".", schema)
    stopifnot(validation$valid, identical(validation, core$read_json_strict(paths$validation)))
    closure_negative_checks(bundle, config, core, schema)
    stopifnot(identical(before_hashes, vapply(before_files, pilot_sha256, "")))
    message("Closure recheck passed: 21 controls, 20 records, exact six outputs/PNG, immutable closure bytes.")
    return(invisible(NULL))
  }
  paths <- lapply(policy$output_names, function(name) file.path(closure$directory, name))
  stopifnot(file.copy(file.path(policy$audit_directory, policy$output_names$baseline), paths$baseline), file.copy(baseline_config, paths$baseline_config))
  environment <- core$read_json_strict(file.path(policy$audit_directory, policy$output_names$environment))
  for (name in names(environment$packages)) stopifnot(environment$packages[[name]] == as.character(utils::packageVersion(name)))
  stopifnot(environment$r_version == R.version.string)
  environment$closure_script_sha256 <- pilot_sha256(closure$producer)
  pilot_write_json(environment, paths$environment)
  pilot_write_json(result$audit, paths$audit)
  pilot_write_json(result$checks, paths$checks)
  bundle <- closure_bundle(config, result$audit, environment, old_bundle, decisions)
  pilot_write_json(bundle, paths$bundle)
  bundle <- core$read_json_strict(paths$bundle)
  validation <- core$validate_bundle(bundle, ".", schema)
  if (!validation$valid) { print(validation$findings); stop("Closure validation failed") }
  stopifnot(length(bundle$records) == 20L, length(validation$findings) == 0L)
  mutation <- closure_negative_checks(bundle, config, core, schema)
  pilot_write_json(mutation, paths$mutation_checks)
  pilot_write_json(validation, paths$validation)
  acceptance <- list(status = "accepted", delivery_disposition = "qualified_answer", applied_at = pilot_time(),
    reviewer = decisions$reviewer, review_mode = decisions$review_mode, identity_basis = decisions$identity_basis,
    review_time_basis = decisions$review_time_basis, human_source_sha256 = pilot_sha256(closure$request),
    dispositions = lapply(decisions$items, function(item) c(item, list(final_status = "accepted", editorial_revision_required = item$human_disposition == "ACCEPT WITH EDIT", approved_edit_applied = item$human_disposition == "ACCEPT WITH EDIT"))),
    limitations = decisions$limitations, retrospective = TRUE, preregistration_claimed = FALSE,
    whole_report_rerendered = FALSE, common_scientific_certification = "not_assessed",
    original_record_count = length(old_bundle$records), accepted_record_count = length(bundle$records),
    historical_bundle_sha256 = pilot_sha256(file.path(policy$audit_directory, policy$output_names$bundle)),
    original_html_sha256 = pilot_sha256(config$artifacts$argentina_dengue_portfolio_report_html),
    accepted_fragment_sha256 = pilot_sha256(fragment_path),
    editorial_byte_change_cause = "New standalone selected-section document; exact approved introduction and alt text, preserved full limitations and document wrapper. Original report/source/PNG bytes unchanged.",
    png = result$audit$png_reproduction, audit_control_count = length(result$checks), validation_valid = validation$valid)
  pilot_write_json(acceptance, file.path(closure$directory, closure$acceptance_name))
  setwd(root)
  if (!file.rename(file.path(stage, closure$directory), final)) stop("Atomic closure publication failed")
  message("Accepted retrospective closure published: 20 records; 21 controls; no unresolved review requirements.")
}

if (sys.nframe() == 0L) main()
