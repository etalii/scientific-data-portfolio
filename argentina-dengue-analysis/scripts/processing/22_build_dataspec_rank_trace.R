# Register the completed retrospective rank audit in DataSpec.
# Inputs: governed project configuration, immutable audit metadata, assistant review.
# Outputs: new bundle, common validation result, and bounded mutation-test metadata.

# Build typed DataSpec records from an already completed audit, without re-analysis.
build_rank_records <- function(config, audit, environment) {
  policy <- config$dataspec_rank_pilot
  stamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  paths <- lapply(policy$output_names, function(name) file.path(policy$audit_directory, name))
  reference <- function(id) list(project_id = policy$project_id, artifact_id = id, revision = as.integer(policy$revision))
  references <- function(ids) lapply(sort(unique(ids), method = "radix"), reference)
  external <- function(path, locator) {
    list(path = path, sha256 = pilot_sha256(path), locator = locator, availability = "verified_local")
  }
  external_set <- function(values) {
    keys <- vapply(values, function(x) paste(x$path, x$sha256, x$locator, sep = "\t"), "")
    values[order(keys, method = "radix")]
  }
  artifact <- function(id, kind, payload, dependencies = character()) {
    list(schema_version = "0.1.0", project_id = policy$project_id,
         study_id = policy$study_id, artifact_id = id, revision = as.integer(policy$revision),
         kind = kind, owner = policy$record_owner, created_at = stamp,
         record_origin = "retrospective", status = "draft", depends_on = references(dependencies),
         limitations = list("Retrospective, bounded audit; human acceptance is not inferred."), payload = payload)
  }
  scope <- audit$scope
  caveats <- list("Published-count rates are descriptive, not incidence, unique persons, or individual risk.",
                  "Territorial numerators exclude unknown/nonassignable geography without redistribution.",
                  "Calendar-year 2024 is not the SE31/2024-SE30/2025 seasonal scope.")
  records <- list(artifact("question", "question", list(
    question_text = "How does population adjustment change the existing provincial published-count ordering in calendar year 2024?",
    intended_use = "Audit the traceability of an already published descriptive comparison.", audience = "Scientific portfolio readers and reviewers",
    scope = scope, non_goals = list("Causal or individual-risk inference", "New indicators or seasonal claims"),
    answer_criteria = list("Recover the four published rank shifts from the governed artifacts and preserve their interpretation limits."))))
  contracts <- list(
    list(id = "contract_c16", contract_id = "published_count_rate_indicators", document = policy$rate_contract, producer = policy$rate_producer),
    list(id = "contract_c20", contract_id = "epidemiological_portfolio_visualization", document = policy$visualization_contract, producer = policy$visualization_producer),
    list(id = "contract_pilot", contract_id = "dataspec_rank_pilot", document = policy$contract, producer = policy$audit_script))
  for (item in contracts) records <- c(records, list(artifact(item$id, "data_contract_ref", list(
    contract_id = item$contract_id, contract_version = "1.0.0", document_ref = external(item$document, "Identity; scope; validation"),
    producer_ref = external(item$producer, "main and owned helper functions"), consumer_roles = list("retrospective_auditor", "report_reviewer")))))
  metric_policy <- function(rule) list(rule = rule, authority_ref = external(policy$rate_contract, "Geographic policy; week coverage; grains"))
  for (kind in c("count", "rate")) {
    denominator <- list(applicable = kind == "rate", reason = if (kind == "rate") "Official province population for the matching year and vintage." else "A count has no denominator.")
    if (kind == "rate") denominator$definition_ref <- external(policy$population_contract, "Population scope and reference date")
    records <- c(records, list(artifact(paste0("metric_", kind), "metric", list(
      contract_ref = reference("contract_c16"), definition_locator = "Artifacts and common fields; grains and fields",
      grain = "analysis_scope_id + denominator_scenario + reference_province_id",
      unit = if (kind == "rate") "published counts per 100000 population" else "published counts",
      dimensions = list("reference_province_id"), population_or_domain = "Mapped published surveillance counts in 24 INDEC jurisdictions",
      time_basis = "Calendar year 2024; observed weeks W01-W52", spatial_basis = list(applicable = TRUE, description = "INDEC jurisdiction; validated source mapping"),
      scope = scope, metric_type = kind, denominator = denominator,
      missingness_policy = metric_policy("Do not redistribute unknown geography or fill absent rows."),
      aggregation_policy = metric_policy("Use already governed C.16 aggregates; rates are not additive."),
      join_policy = metric_policy("Use validated exact province IDs and matching population year/vintage."),
      computation_ref = external(policy$rate_producer, if (kind == "rate") "published_count_rate; main" else "main: governed C.12 numerator hand-off"),
      interpretation_limits = caveats))))
  }
  records <- c(records, list(artifact("plan", "analysis_plan", list(
    question_ref = reference("question"), design_type = "descriptive",
    methods = list("Reconstruct the existing question retrospectively.", "Reproduce C.16 and the selected C.20 figure in isolation; compare exact bytes.", "Independently reconcile ranks and verify the archived selected report section."),
    contract_refs = references(c("contract_c16", "contract_c20", "contract_pilot")), metric_refs = references(c("metric_count", "metric_rate")),
    hypothesis_refs = list(), hypothesis_omission_reason = "Descriptive retrospective comparison; no historical confirmatory timing is claimed.",
    validation_strategy = "21 mechanical checks, recorded assistant review, common trace validation, and in-memory stale propagation.",
    sensitivity_policy = "Contemporary scenario only; this pilot makes no denominator-sensitivity result claim.",
    stopping_rule = "Close the mechanical audit on exact reconciliation; retain the human-review gate."))))
  input_refs <- lapply(audit$inputs, function(x) external(x$path, "C.16 input artifact; schema governed by its existing contract"))
  records <- c(records, list(artifact("execution_audit", "execution", list(
    plan_ref = reference("plan"), command = audit$command, working_directory = ".",
    code_refs = external_set(list(external(policy$audit_script, "main"), external(policy$rate_producer, "main"), external(policy$visualization_producer, "rank_measure; build_province_rank_plot; render_png"))),
    config_refs = external_set(list(external("config/project.yml", "dataspec_rank_pilot and existing analytical configuration"), external(paths$baseline_config, "Exact pre-pilot analytical configuration"))),
    environment_ref = external(paths$environment, "R and installed versions; code identities"),
    input_refs = external_set(input_refs), output_refs = external_set(list(external(paths$audit, "Audit comparisons and timestamps"), external(paths$checks, "All 21 checks"))),
    started_at = audit$started_at, finished_at = audit$finished_at, exit_code = 0L,
    validation_refs = list(external(paths$checks, "All 21 checks")), reproduction_status = audit$reproduction_status))))
  records <- c(records, list(artifact("evidence_ranks", "evidence", list(
    evidence_type = "computational",
    source_refs = external_set(list(external(config$artifacts$epidemiology_province_summary, "analysis_scope_id=dengue_2024; denominator_scenario=contemporary; all 24 reference_province_id rows"),
                                   external(paths$audit, "featured_rank_checks; c16_reproduction; png_reproduction"))),
    execution_refs = references("execution_audit"), result_locator = "featured_rank_checks; rank_06, rank_90, rank_46, rank_10 checks",
    scope = scope, finding = "The four published count-to-rate rank pairs agree with the governed indicators, independent ordering, figure, and archived prose.",
    uncertainty = "Descriptive published-count semantics and incomplete geographic assignment; no sampling or causal uncertainty estimate is inferred.",
    validation_refs = list(external(paths$checks, "rate_formula; population_reference; geographic_eligibility; rank and report checks"))))))
  claim_ids <- "claim_population_adjustment"
  claim_texts <- list("Population adjustment changes the provincial ordering of published counts in calendar year 2024 under the contemporary scenario.")
  for (item in audit$featured_rank_checks) {
    claim_ids <- c(claim_ids, paste0("claim_province_", item$reference_province_id))
    claim_texts <- c(claim_texts, list(sprintf("%s: count rank %s to rate rank %s.", item$reference_province_name, item$observed_count_rank, item$observed_rate_rank)))
  }
  for (i in seq_along(claim_ids)) records <- c(records, list(artifact(claim_ids[[i]], "claim", list(
    question_ref = reference("question"), claim_text = claim_texts[[i]], claim_type = "descriptive",
    supporting_evidence_refs = references("evidence_ranks"), contradicting_evidence_refs = list(),
    metric_refs = references(c("metric_count", "metric_rate")), scope = scope, caveats = caveats, disposition = "qualified"))))
  records <- c(records, list(artifact("narrative", "narrative_spec", list(
    audience = "Scientific portfolio readers", communication_goal = "Explain why published-count and population-adjusted ordering differ without implying disease risk.",
    ordered_sections = list(list(section_id = "population_adjustment", text = "Existing provincial rank-shift section: four rank statements, slopegraph, featured table, and geographic caveat.", claim_refs = references(claim_ids), context_source_refs = list())),
    claim_refs = references(claim_ids), context_source_refs = list(), mandatory_caveats = caveats, excluded_claims_with_reasons = list()))))
  records <- c(records, list(artifact("visual", "visualization_spec", list(
    claim_refs = references(claim_ids), metric_refs = references(c("metric_count", "metric_rate")),
    input_refs = list(external(config$artifacts$epidemiology_province_summary, "dengue_2024 / contemporary / all 24 jurisdictions")),
    chart_type = "slopegraph", encodings = list(list(channel = "x", field = "measure_rank_type", description = "Published count rank on left; published-count rate rank on right."),
      list(channel = "y", field = "rank", description = "Ordinal rank 1 at top through 24; descending measure and province ID tie-break."),
      list(channel = "group", field = "reference_province_id", description = "Connect the same jurisdiction across axes; direct labels for four featured provinces.")),
    transformations = list(list(operation = "ordinal_order", category = "display", description = "Deterministic ordering from existing measures, checked against C.20.")),
    labels = list(title = "Population adjustment changes the territorial ordering", caption = paste(unlist(caveats[1:2]), collapse = " "),
                  alt_text = "24 provincial count/rate ranks; Buenos Aires 1 to 16, Tucuman 3 to 1, La Rioja 12 to 2, Catamarca 13 to 4."),
    uncertainty_display = "Explicit semantic/geographic caveats; no invented confidence intervals.",
    accessibility_criteria = list("Direct labels, positional encoding and HTML alternative text."),
    render_targets = list("Existing English PNG and its embedded HTML copy"),
    qa_criteria = list("Independent rank reconciliation", "2400x1800 PNG validation and byte-identical isolated rerender", "Assistant visual inspection of labels, scope, and caveats")), "contract_c20")))
  review <- artifact("review_automated", "review", list(
    target_refs = references(c(claim_ids, "narrative", "visual")), reviewer = "codex_assistant",
    review_mode = "automated", review_dimensions = as.list(c("narrative", "reproducibility", "scientific", "visual")),
    checks = list(list(check_id = "bounded_assistant_review", result = "pass",
                       evidence_refs = external_set(list(external(policy$review, "All four review dimensions; explicit automated disposition"), external(paths$checks, "21 mechanical checks"))),
                       note = "Assistant review and mechanical checks completed; this is not human acceptance.")),
    findings = list("Human scientific, narrative, visual, and reproducibility review remains pending."),
    disposition = "pass", reviewed_at = stamp))
  review$status <- "accepted"
  records <- c(records, list(review))
  html_ref <- external(config$artifacts$argentina_dengue_portfolio_report_html, paste0("#", policy$report_section_id))
  png_ref <- external(audit$png_reproduction$path, "Full figure; scope/calendar labels and four highlighted provincial paths")
  records <- c(records, list(artifact("delivery", "delivery", list(
    question_ref = reference("question"), deliverable_refs = external_set(list(html_ref, png_ref)),
    spec_refs = references(c("narrative", "visual")), claim_location_map = lapply(claim_ids, function(id) list(claim_ref = reference(id), artifact_ref = html_ref, location = paste0("#", policy$report_section_id, "; #", policy$figure_id))),
    review_refs = references("review_automated"), dependency_snapshot = references(vapply(records, `[[`, "", "artifact_id")),
    reproduction_instructions = "Follow the project pilot contract and study README. Reproduce in isolated storage, using preserved baseline inputs/configuration; never overwrite the existing audit identity.",
    known_gaps = c(audit$historical_gaps, list("Only automated review is recorded; human approval is pending.", "Other report sections and mobile/browser accessibility are outside this audit.")),
    delivery_disposition = "qualified_answer"))))
  records <- records[order(vapply(records, `[[`, "", "artifact_id"), method = "radix")]
  list(schema_version = "0.1.0", adapter = list(project_id = policy$project_id,
    scope_schema_ref = external(policy$scope_schema, "Complete project-local scope schema"),
    required_review_dimensions = as.list(c("narrative", "reproducibility", "scientific", "visual"))),
    candidate_refs = references(vapply(records, `[[`, "", "artifact_id")), records = records)
}

# Register trace metadata only if mechanical validation passes and human gates remain.
main <- function() {
  config <- yaml::read_yaml("config/project.yml")
  policy <- config$dataspec_rank_pilot
  source(policy$audit_script)
  paths <- lapply(policy$output_names, function(name) file.path(policy$audit_directory, name))
  targets <- unlist(paths[c("bundle", "validation", "mutation_checks")])
  if (any(file.exists(targets))) stop("Trace metadata already exists; refuse overwrite")
  audit <- jsonlite::fromJSON(paths$audit, simplifyVector = FALSE)
  environment <- jsonlite::fromJSON(paths$environment, simplifyVector = FALSE)
  stopifnot(identical(environment$audit_script_sha256, pilot_sha256(policy$audit_script)))
  core <- new.env(parent = globalenv())
  sys.source(policy$framework_core, envir = core)
  bundle <- build_rank_records(config, audit, environment)
  staging <- tempfile(".dataspec_trace_", policy$audit_directory)
  dir.create(staging)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  candidate <- file.path(staging, policy$output_names$bundle)
  pilot_write_json(bundle, candidate)
  bundle <- core$read_json_strict(candidate)
  validation <- core$validate_bundle(bundle, ".", policy$framework_schema)
  codes <- vapply(validation$findings, `[[`, "", "code")
  if (validation$valid || !length(codes) || any(codes != "REVIEW")) {
    print(validation$findings)
    stop("Expected only explicit human-review gates after mechanical validation")
  }
  mechanical <- bundle
  mechanical$records <- Filter(function(x) x$kind != "delivery", mechanical$records)
  mechanical$candidate_refs <- Filter(function(x) x$artifact_id != "delivery", mechanical$candidate_refs)
  mechanical_result <- core$validate_bundle(mechanical, ".", policy$framework_schema)
  stopifnot(mechanical_result$valid)
  mutated <- bundle
  index <- which(vapply(mutated$records, function(x) x$artifact_id == "execution_audit", logical(1)))
  mutated$records[[index]]$payload$input_refs[[1]]$sha256 <- paste(rep("0", 64L), collapse = "")
  mutation_result <- core$validate_bundle(mutated, ".", policy$framework_schema)
  state <- setNames(vapply(mutation_result$records, `[[`, "", "readiness"), vapply(mutation_result$records, `[[`, "", "identity"))
  identity <- function(id) sprintf("%s/%s/%012d", policy$project_id, id, policy$revision)
  stopifnot(state[[identity("evidence_ranks")]] == "stale", state[[identity("delivery")]] == "stale",
            state[[identity("claim_province_06")]] == "stale", state[[identity("question")]] == "ready")
  mutation_checks <- list(mechanical_bundle_valid = TRUE, delivery_valid = validation$valid,
    expected_delivery_blockers = as.list(unique(codes)), changed_in_memory_only = TRUE,
    evidence_stale = TRUE, claim_stale = TRUE, delivery_stale = TRUE, unrelated_question_ready = TRUE)
  pilot_write_json(validation, file.path(staging, policy$output_names$validation))
  pilot_write_json(mutation_checks, file.path(staging, policy$output_names$mutation_checks))
  published <- character()
  complete <- FALSE
  on.exit(if (!complete) unlink(published), add = TRUE)
  for (name in c("bundle", "validation", "mutation_checks")) {
    target <- paths[[name]]
    if (!file.rename(file.path(staging, policy$output_names[[name]]), target)) stop("Trace publication failed")
    published <- c(published, target)
  }
  complete <- TRUE
  message(sprintf("Trace registered: %s records; mechanical validation passed; %s explicit human-review gates.", length(bundle$records), length(codes)))
}

if (sys.nframe() == 0L) main()
