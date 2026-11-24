# DataSpec read-only validation library.
# Inputs: parsed JSON bundle, project root, and schema path.
# Outputs: deterministic findings and per-record readiness; no filesystem writes.

# Compare JSON values independently of object key order.
canonical_json <- function(x) {
  if (is.list(x)) {
    if (!is.null(names(x))) x <- x[order(names(x), method = "radix")]
    x <- lapply(x, canonical_value)
  }
  as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null", digits = NA))
}

# Recursively sort JSON object keys, preserving array order and empty objects.
canonical_value <- function(x) {
  if (!is.list(x)) return(x)
  if (!is.null(names(x))) x <- x[order(names(x), method = "radix")]
  lapply(x, canonical_value)
}

# Read UTF-8 JSON without vector simplification or duplicate object keys.
read_json_strict <- function(path) {
  if (!file.exists(path) || dir.exists(path)) stop("JSON input must be an existing local file")
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (!jsonlite::validate(text)) stop("Invalid JSON syntax")
  value <- jsonlite::fromJSON(text, simplifyVector = FALSE)
  check_keys <- function(x) {
    if (!is.list(x)) return(invisible(NULL))
    if (!is.null(names(x)) && anyDuplicated(names(x))) stop("Duplicate JSON object key")
    lapply(x, check_keys)
    invisible(NULL)
  }
  check_keys(value)
  value
}

# Resolve a local schema definition; remote and relative schema references fail.
resolve_schema <- function(reference, root) {
  if (!grepl("^#/\\$defs/[a-z_]+$", reference)) stop("Unsupported schema reference: ", reference)
  name <- sub("^#/\\$defs/", "", reference)
  if (is.null(root$`$defs`[[name]])) stop("Missing schema definition: ", name)
  root$`$defs`[[name]]
}

# Reject unsupported schema keywords and recursive references before validation.
check_schema_profile <- function(schema, root = schema, stack = character()) {
  allowed <- c("$schema", "$id", "title", "description", "$ref", "$defs", "type",
               "properties", "required", "additionalProperties", "propertyNames",
               "items", "minItems", "uniqueItems", "minLength", "pattern", "minimum",
               "enum", "const", "allOf", "oneOf")
  if (!is.list(schema) || is.null(names(schema))) stop("Schema must be an object")
  unknown <- setdiff(names(schema), allowed)
  if (length(unknown)) stop("Unsupported schema keyword: ", unknown[1])
  if (!is.null(schema$`$ref`)) {
    reference <- schema$`$ref`
    if (reference %in% stack) stop("Cyclic schema reference: ", reference)
    check_schema_profile(resolve_schema(reference, root), root, c(stack, reference))
  }
  for (field in c("properties", "$defs")) {
    for (child in schema[[field]]) check_schema_profile(child, root, stack)
  }
  for (field in c("allOf", "oneOf")) {
    for (child in schema[[field]]) check_schema_profile(child, root, stack)
  }
  for (field in c("items", "propertyNames")) {
    if (!is.null(schema[[field]])) check_schema_profile(schema[[field]], root, stack)
  }
  if (!is.null(schema$additionalProperties) && !is.logical(schema$additionalProperties)) {
    stop("additionalProperties must be boolean in this profile")
  }
  invisible(TRUE)
}

# Test a parsed JSON value's type without coercing arrays or scalar strings.
json_type_matches <- function(value, type) {
  switch(type,
    object = is.list(value) && !is.null(names(value)),
    array = is.list(value) && is.null(names(value)),
    string = is.character(value) && length(value) == 1L && !is.na(value),
    boolean = is.logical(value) && length(value) == 1L && !is.na(value),
    integer = is.numeric(value) && length(value) == 1L && is.finite(value) && value == floor(value),
    number = is.numeric(value) && length(value) == 1L && is.finite(value),
    `null` = is.null(value),
    stop("Unsupported schema type: ", type)
  )
}

# Validate the supported JSON Schema profile and return field-level messages.
schema_errors <- function(value, schema, root = schema, path = "$") {
  errors <- character()
  add <- function(message) errors <<- c(errors, paste(path, message))
  if (!is.null(schema$`$ref`)) {
    errors <- c(errors, schema_errors(value, resolve_schema(schema$`$ref`, root), root, path))
  }
  for (child in schema$allOf) errors <- c(errors, schema_errors(value, child, root, path))
  if (!is.null(schema$oneOf)) {
    alternatives <- lapply(schema$oneOf, function(s) schema_errors(value, s, root, path))
    if (sum(lengths(alternatives) == 0L) != 1L) {
      add("must match exactly one schema alternative")
      if (all(lengths(alternatives) > 0L)) errors <- c(errors, alternatives[[which.min(lengths(alternatives))]])
    }
  }
  if (!is.null(schema$type)) {
    types <- unlist(schema$type, use.names = FALSE)
    if (!any(vapply(types, function(t) json_type_matches(value, t), logical(1)))) {
      add(paste("expected", paste(types, collapse = " or ")))
      return(errors)
    }
  }
  if ("const" %in% names(schema) && canonical_json(value) != canonical_json(schema$const)) add("incorrect constant")
  if (!is.null(schema$enum) && !canonical_json(value) %in% vapply(schema$enum, canonical_json, "")) add("value outside vocabulary")
  if (json_type_matches(value, "object")) {
    missing <- setdiff(unlist(schema$required), names(value))
    if (length(missing)) add(paste("missing fields:", paste(missing, collapse = ", ")))
    if (identical(schema$additionalProperties, FALSE)) {
      extra <- setdiff(names(value), names(schema$properties))
      if (length(extra)) add(paste("unknown fields:", paste(extra, collapse = ", ")))
    }
    for (name in names(value)) {
      if (!is.null(schema$propertyNames)) errors <- c(errors, schema_errors(name, schema$propertyNames, root, paste0(path, ".", name)))
      if (!is.null(schema$properties[[name]])) errors <- c(errors, schema_errors(value[[name]], schema$properties[[name]], root, paste0(path, ".", name)))
    }
  }
  if (json_type_matches(value, "array")) {
    if (!is.null(schema$minItems) && length(value) < schema$minItems) add("too few array entries")
    if (isTRUE(schema$uniqueItems) && anyDuplicated(vapply(value, canonical_json, ""))) add("duplicate array entries")
    if (!is.null(schema$items)) for (i in seq_along(value)) errors <- c(errors, schema_errors(value[[i]], schema$items, root, paste0(path, "[", i, "]")))
  }
  if (json_type_matches(value, "string")) {
    if (!is.null(schema$minLength) && nchar(value, type = "chars") < schema$minLength) add("string too short")
    if (!is.null(schema$pattern) && !grepl(schema$pattern, value, perl = TRUE)) add("string does not match pattern")
  }
  if (is.numeric(value) && length(value) == 1L && !is.null(schema$minimum) && value < schema$minimum) add("number below minimum")
  errors
}

# Format stable internal identities for sorting and diagnostic paths.
ref_key <- function(x) paste(x$project_id, x$artifact_id, sprintf("%012.0f", x$revision), sep = "/")

# Collect structurally typed references at any depth with their source locations.
collect_refs <- function(value, type, path = "$") {
  result <- list()
  if (!is.list(value)) return(result)
  fields <- if (type == "internal") c("project_id", "artifact_id", "revision") else c("path", "sha256", "locator", "availability")
  matches <- if (type == "internal") setequal(names(value), fields) else all(fields %in% names(value))
  if (matches) return(list(list(value = value, path = path)))
  for (i in seq_along(value)) {
    label <- if (is.null(names(value))) paste0("[", i, "]") else paste0(".", names(value)[i])
    result <- c(result, collect_refs(value[[i]], type, paste0(path, label)))
  }
  result
}

# Resolve a file within the root, rejecting traversal, absolute paths, and symlink escapes.
safe_file <- function(path, root) {
  if (grepl("(^/|\\\\|^[A-Za-z]:|(^|/)\\.\\.?(/|$)|//)", path) || endsWith(path, "/")) return(NULL)
  candidate <- file.path(root, path)
  if (!file.exists(candidate) || dir.exists(candidate)) return(NULL)
  resolved <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
  if (!startsWith(resolved, paste0(root, "/"))) return(NULL)
  resolved
}

# Validate a real UTC calendar timestamp, including round-trip calendar checking.
valid_timestamp <- function(value) {
  if (is.null(value)) return(FALSE)
  parsed <- as.POSIXct(value, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  !is.na(parsed) && identical(format(parsed, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), value)
}

# Check per-record scientific prerequisites and conditional fields.
validate_payload <- function(x, key, records, scope_schema, add) {
  p <- x$payload
  keys <- names(records)
  if (!valid_timestamp(x$created_at)) add("SCHEMA", key, "created_at", "Invalid UTC calendar timestamp")
  if (!length(x$limitations) && is.null(p$limitations_justification)) add("SCHEMA", key, "limitations", "Empty limitations require justification")
  if (!is.null(p$scope) && !is.null(scope_schema)) for (error in schema_errors(p$scope, scope_schema)) add("SCOPE", key, "payload.scope", error)
  if (x$kind == "analysis_plan" && !length(p$hypothesis_refs) && is.null(p$hypothesis_omission_reason)) add("SCHEMA", key, "hypothesis_refs", "Empty hypotheses require omission reason")
  if (x$kind == "metric") {
    d <- p$denominator
    if ((p$metric_type %in% c("rate", "ratio") && !d$applicable) || (d$applicable && is.null(d$definition_ref))) add("DENOMINATOR", key, "denominator", "Ratio/rate requires an applicable documented denominator")
  }
  if (x$kind == "hypothesis") {
    if (is.null(p$formulated_at) && is.null(p$timing_unknown_reason)) add("TIMING", key, "formulated_at", "Unknown timing requires a reason")
    for (field in c("formulated_at", "results_observed_at")) if (!is.null(p[[field]]) && !valid_timestamp(p[[field]])) add("TIMING", key, field, "Invalid timestamp")
    if (p$hypothesis_type == "confirmatory" && (is.null(p$formulated_at) || is.null(p$results_observed_at) || !length(p$timing_evidence_refs) || (!is.null(p$formulated_at) && !is.null(p$results_observed_at) && p$formulated_at >= p$results_observed_at))) add("TIMING", key, "hypothesis_type", "Confirmatory status requires preserved timing evidence preceding result observation")
  }
  if (x$kind == "execution") {
    for (field in c("started_at", "finished_at")) if (!is.null(p[[field]]) && !valid_timestamp(p[[field]])) add("TIMING", key, field, "Invalid timestamp")
    incomplete <- is.null(p$started_at) || is.null(p$finished_at) || is.null(p$exit_code)
    if (incomplete && is.null(p$execution_gap_reason)) add("EVIDENCE", key, "execution_gap_reason", "Incomplete execution history requires a gap reason")
    if (!incomplete && p$started_at > p$finished_at) add("TIMING", key, "finished_at", "Execution ends before it starts")
    if (p$reproduction_status == "passed" && (incomplete || p$exit_code != 0 || !length(p$validation_refs))) add("EVIDENCE", key, "reproduction_status", "Passed reproduction requires successful dated execution and preserved checks")
  }
  if (x$kind == "evidence" && p$evidence_type == "computational" && !length(p$execution_refs)) add("EVIDENCE", key, "execution_refs", "Computational evidence requires an execution")
  if (x$kind == "claim") {
    if (p$disposition %in% c("supported", "qualified") && !length(p$supporting_evidence_refs)) add("CLAIM", key, "supporting_evidence_refs", "Supported/qualified claim requires evidence")
    if (p$claim_type == "causal" && is.null(p$causal_authorization_ref)) add("CLAIM", key, "claim_type", "Causal claims require explicit project authorization")
  }
  if (x$kind == "review") {
    if (!valid_timestamp(p$reviewed_at)) add("TIMING", key, "reviewed_at", "Invalid timestamp")
    if (p$disposition == "pass" && any(vapply(p$checks, function(z) z$result != "pass", logical(1)))) add("REVIEW", key, "checks", "Passing review contains failed or unresolved checks")
    if (p$review_mode == "independent") for (target in p$target_refs) {
      t <- ref_key(target)
      if (t %in% keys && p$reviewer == records[[t]]$owner) add("REVIEW", key, "reviewer", "Independent reviewer equals target owner")
    }
    dimensions <- unlist(p$review_dimensions)
    if (!identical(dimensions, sort(unique(dimensions), method = "radix"))) add("SCHEMA", key, "review_dimensions", "Review dimensions must be sorted and unique")
    for (target in p$target_refs) {
      t <- ref_key(target)
      if (t %in% keys && p$reviewed_at < records[[t]]$created_at) add("TIMING", key, "reviewed_at", "Review predates target revision")
    }
  }
}

# Report graph cycles without requiring topological input order.
check_cycles <- function(graph, add) {
  keys <- names(graph)
  colors <- setNames(integer(length(keys)), keys)
  visit <- function(key) {
    if (colors[[key]] == 1L) { add("CYCLE", key, "depends_on", "Dependency cycle detected"); return() }
    if (colors[[key]] == 2L) return()
    colors[[key]] <<- 1L
    for (target in intersect(graph[[key]], keys)) visit(target)
    colors[[key]] <<- 2L
  }
  for (key in keys) visit(key)
  invisible(NULL)
}

# Return transitive dependencies even for a graph containing a reported cycle.
dependency_closure <- function(start, graph) {
  keys <- names(graph)
  found <- character(); pending <- graph[[start]]
  while (length(pending)) {
    target <- pending[1]; pending <- pending[-1]
    if (target %in% found || !target %in% keys) next
    found <- c(found, target); pending <- c(pending, graph[[target]])
  }
  sort(setdiff(found, start), method = "radix")
}

# Verify delivery closure, claim mapping, and required human review coverage.
validate_delivery <- function(x, key, records, graph, reviewed, add) {
  p <- x$payload
  keys <- names(records)
  review_keys <- vapply(p$review_refs, ref_key, "")
  claim_keys <- vapply(p$claim_location_map, function(z) ref_key(z$claim_ref), "")
  spec_keys <- vapply(p$spec_refs, ref_key, "")
  snapshot <- vapply(p$dependency_snapshot, ref_key, "")
  # Compute closure without snapshot edges so an extra record cannot justify itself.
  saved <- graph[[key]]
  direct <- collect_refs(p[setdiff(names(p), "dependency_snapshot")], "internal")
  graph[[key]] <- unique(c(vapply(direct, function(z) ref_key(z$value), ""), vapply(x$depends_on, ref_key, "")))
  expected <- dependency_closure(key, graph); graph[[key]] <- saved
  if (!setequal(snapshot, expected)) add("DELIVERY", key, "dependency_snapshot", "Snapshot is not the exact dependency closure")
  for (ancestor in c(key, expected)) {
    for (external in collect_refs(records[[ancestor]]$payload, "external")) {
      if (external$value$availability != "verified_local") add("UNAVAILABLE", key, "dependency_snapshot", paste("Delivery depends on unavailable evidence in", ancestor))
    }
    if (records[[ancestor]]$status %in% c("rejected", "superseded")) add("DELIVERY", key, "dependency_snapshot", paste("Delivery includes rejected/superseded record", ancestor))
  }
  spec_kinds <- vapply(records[intersect(spec_keys, keys)], `[[`, "", "kind")
  if (!all(c("narrative_spec", "visualization_spec") %in% spec_kinds)) add("DELIVERY", key, "spec_refs", "Delivery requires narrative and visual specifications")
  for (t in intersect(claim_keys, keys)) {
    if (records[[t]]$kind != "claim") next
    disposition <- records[[t]]$payload$disposition
    if (p$delivery_disposition == "answer" && disposition != "supported") add("CLAIM", key, "claim_location_map", "Answer requires supported claims")
    if (p$delivery_disposition == "qualified_answer" && !disposition %in% c("supported", "qualified")) add("CLAIM", key, "claim_location_map", "Qualified answer includes unsupported claim")
    if (p$delivery_disposition == "inconclusive" && disposition == "unsupported") add("CLAIM", key, "claim_location_map", "Inconclusive delivery must explain uncertainty rather than include an unsupported assertion")
    if (!reviewed(t, "scientific", review_keys)) add("REVIEW", key, "review_refs", "Delivered claim lacks human scientific review")
  }
  if (p$delivery_disposition == "inconclusive" && (is.null(p$inconclusive_reason) || !length(p$known_gaps))) add("DELIVERY", key, "inconclusive_reason", "Inconclusive delivery needs reason and known gaps")
  artifact_ids <- vapply(p$deliverable_refs, function(z) paste(z$path, z$sha256), "")
  for (location in p$claim_location_map) if (!paste(location$artifact_ref$path, location$artifact_ref$sha256) %in% artifact_ids) add("DELIVERY", key, "claim_location_map", "Claim location is outside declared deliverables")
  for (t in intersect(spec_keys, keys)) {
    spec <- records[[t]]
    required <- if (spec$kind == "visualization_spec") c("visual", "reproducibility") else c("narrative", "reproducibility")
    for (dimension in required) if (!reviewed(t, dimension, review_keys)) add("REVIEW", key, "review_refs", paste("Missing", dimension, "review for", t))
    mentioned <- vapply(spec$payload$claim_refs, ref_key, "")
    if (!all(mentioned %in% claim_keys)) add("DELIVERY", key, "claim_location_map", "Specification contains an unmapped claim")
    if (spec$kind == "narrative_spec") {
      section_claims <- unlist(lapply(spec$payload$ordered_sections, function(z) vapply(z$claim_refs, ref_key, "")), use.names = FALSE)
      if (!setequal(section_claims, mentioned)) add("DELIVERY", key, "spec_refs", "Narrative sections and declared claims differ")
      section_sources <- unlist(lapply(spec$payload$ordered_sections, function(z) vapply(z$context_source_refs, canonical_json, "")), use.names = FALSE)
      if (!all(section_sources %in% vapply(spec$payload$context_source_refs, canonical_json, ""))) add("DELIVERY", key, "spec_refs", "Narrative section context source is undeclared")
    }
  }
}

# Reject duplicate or unordered reference sets without modifying input.
check_sets <- function(value, key, add, path = "$") {
  if (!is.list(value)) return()
  if (is.null(names(value)) && length(value)) {
    is_refs <- all(vapply(value, function(z) is.list(z) && setequal(names(z), c("project_id", "artifact_id", "revision")), logical(1)))
    if (is_refs) {
      values <- vapply(value, ref_key, "")
      if (anyDuplicated(values) || !identical(values, sort(values, method = "radix"))) add("SCHEMA", key, path, "Reference set must be unique and identity-sorted")
    }
    is_external <- all(vapply(value, function(z) is.list(z) && all(c("path", "sha256", "locator", "availability") %in% names(z)), logical(1)))
    if (is_external) {
      values <- vapply(value, function(z) paste(z$path, z$sha256, z$locator, sep = "\t"), "")
      if (anyDuplicated(values) || !identical(values, sort(values, method = "radix"))) add("SCHEMA", key, path, "External reference set must be unique and path/hash/locator-sorted")
    }
  }
  for (i in seq_along(value)) check_sets(value[[i]], key, add, paste0(path, ".", if (is.null(names(value))) i else names(value)[i]))
}

# Propagate an invalidation flag only through actual dependency edges.
propagate_flags <- function(flags, graph) {
  repeat {
    before <- flags
    for (key in names(graph)) {
      if (any(flags[intersect(graph[[key]], names(flags))])) flags[[key]] <- TRUE
    }
    if (identical(before, flags)) return(flags)
  }
}

# Validate bundle structure, file integrity, dependencies, and recorded acceptance.
validate_bundle <- function(bundle, project_root, schema_path) {
  root <- normalizePath(project_root, winslash = "/", mustWork = TRUE)
  schema <- read_json_strict(schema_path)
  check_schema_profile(schema)
  findings <- list()
  add <- function(code, record, field, message, severity = "error") {
    findings[[length(findings) + 1L]] <<- list(code = code, severity = severity,
      record = record, field = field, message = message)
  }
  finish <- function(states = list()) {
    if (length(findings)) {
      sort_keys <- vapply(findings, function(x) paste(x$record, x$field, x$code, x$message), "")
      findings <- findings[order(sort_keys, method = "radix")]
    }
    list(schema_version = "0.1.0", valid = !any(vapply(findings, function(x) x$severity == "error", logical(1))),
         certification = "not_assessed", findings = findings, records = states)
  }
  errors <- schema_errors(bundle, schema)
  if (length(errors)) {
    for (message in errors) add("SCHEMA", "bundle", "$", message)
    return(finish())
  }
  records <- bundle$records
  keys <- vapply(records, ref_key, "")
  if (anyDuplicated(keys)) {
    add("IDENTITY", "bundle", "records", "Duplicate artifact identity")
    return(finish())
  }
  records <- records[order(keys, method = "radix")]
  keys <- sort(keys, method = "radix")
  names(records) <- keys
  selected <- vapply(bundle$candidate_refs, ref_key, "")
  selected_names <- vapply(bundle$candidate_refs, function(x) paste(x$project_id, x$artifact_id), "")
  if (anyDuplicated(selected_names)) add("IDENTITY", "bundle", "candidate_refs", "Select exactly one revision per artifact")
  for (key in setdiff(selected, keys)) add("REFERENCE", "bundle", "candidate_refs", paste("Missing selected record", key))
  for (key in keys) {
    x <- records[[key]]
    if (x$project_id != bundle$adapter$project_id) add("REFERENCE", key, "project_id", "Cross-project bundles are not supported")
    if (is.null(x$study_id) && !(x$kind == "change" && x$project_id == "dataspec")) add("IDENTITY", key, "study_id", "Only framework changes allow null study_id")
    if (x$project_id == "dataspec" && x$kind != "change") add("IDENTITY", key, "project_id", "The dataspec project identity is reserved for framework changes")
    if (!paste(x$project_id, x$artifact_id) %in% selected_names) add("REFERENCE", key, "candidate_refs", "Artifact has no candidate selection")
  }
  studies <- unique(vapply(records, function(x) if (is.null(x$study_id)) "" else x$study_id, ""))
  if (length(studies) > 1L) add("IDENTITY", "bundle", "records", "A bundle must contain one study")
  graph <- setNames(vector("list", length(keys)), keys)
  stale <- setNames(rep(FALSE, length(keys)), keys)
  file_cache <- new.env(parent = emptyenv())
  verify_external <- function(external, key, field, accepted = FALSE) {
    if (external$availability == "unavailable") {
      if (is.null(external$reason)) add("SCHEMA", key, field, "Unavailable reference requires reason")
      add("UNAVAILABLE", key, field, "Reference is explicitly unavailable", if (accepted) "error" else "warning")
      return(FALSE)
    }
    if (is.null(external$sha256) || is.null(external$locator)) {
      add("SCHEMA", key, field, "Verified reference requires SHA-256 and locator"); return(FALSE)
    }
    file <- safe_file(external$path, root)
    if (is.null(file)) {
      add("PATH", key, field, "Missing file, invalid path, or path escapes project root"); return(FALSE)
    }
    if (!exists(file, envir = file_cache, inherits = FALSE)) assign(file, digest::digest(file = file, algo = "sha256"), envir = file_cache)
    if (get(file, envir = file_cache) != external$sha256) {
      add("HASH", key, field, "File SHA-256 does not match declared bytes")
      if (key %in% keys) stale[[key]] <<- TRUE
      return(FALSE)
    }
    TRUE
  }
  scope_schema <- NULL
  if (verify_external(bundle$adapter$scope_schema_ref, "bundle", "adapter.scope_schema_ref", TRUE)) {
    scope_schema <- read_json_strict(safe_file(bundle$adapter$scope_schema_ref$path, root))
    check_schema_profile(scope_schema)
  }
  # Resolve kind-constrained references before using semantic relationships.
  kind_rules <- list(question_ref = "question", plan_ref = "analysis_plan", contract_ref = "data_contract_ref",
    contract_refs = "data_contract_ref", metric_refs = "metric", hypothesis_refs = "hypothesis",
    execution_refs = "execution", supporting_evidence_refs = "evidence", contradicting_evidence_refs = "evidence",
    claim_ref = "claim", claim_refs = "claim", review_refs = "review", spec_refs = c("narrative_spec", "visualization_spec"))
  for (key in keys) {
    x <- records[[key]]; p <- x$payload
    refs <- collect_refs(list(depends_on = x$depends_on, payload = p, supersedes = x$supersedes), "internal")
    graph[[key]] <- unique(vapply(refs, function(z) ref_key(z$value), ""))
    for (reference in refs) {
      target <- ref_key(reference$value)
      if (!target %in% keys) { add("REFERENCE", key, reference$path, paste("Missing target", target)); next }
      field <- sub(".*\\.", "", sub("\\[[0-9]+\\]$", "", reference$path))
      if (!is.null(kind_rules[[field]]) && !records[[target]]$kind %in% kind_rules[[field]]) add("REFERENCE", key, reference$path, "Wrong target artifact kind")
      if (!target %in% selected && field != "supersedes") stale[[key]] <- TRUE
    }
    if (!is.null(x$supersedes)) {
      old <- x$supersedes
      if (old$project_id != x$project_id || old$artifact_id != x$artifact_id || old$revision >= x$revision) add("IDENTITY", key, "supersedes", "Supersession must identify an earlier revision of the same artifact")
      if (ref_key(old) %in% keys && records[[ref_key(old)]]$kind != x$kind) add("IDENTITY", key, "supersedes", "Artifact kind cannot change between revisions")
      # Supersession documents history, not a computational dependency.
      graph[[key]] <- setdiff(graph[[key]], ref_key(old))
    }
    for (external in collect_refs(p, "external")) verify_external(external$value, key, external$path, x$status == "accepted")
    validate_payload(x, key, records, scope_schema, add)
  }
  check_cycles(graph, add)
  # Match human review attestations; automatic verification never establishes support.
  reviewed <- function(target, dimension, allowed = keys) {
    any(vapply(records[intersect(keys, allowed)], function(x) {
      p <- x$payload
      x$kind == "review" && x$status == "accepted" && ref_key(x) %in% selected &&
        p$disposition == "pass" && p$review_mode != "automated" &&
        dimension %in% unlist(p$review_dimensions) &&
        target %in% vapply(p$target_refs, ref_key, "") &&
        all(vapply(p$checks, function(z) z$result == "pass", logical(1)))
    }, logical(1)))
  }
  for (key in keys) {
    x <- records[[key]]; p <- x$payload
    if (x$kind == "claim") {
      for (target in c(p$supporting_evidence_refs, p$contradicting_evidence_refs, p$metric_refs, list(p$question_ref))) {
        t <- ref_key(target)
        if (t %in% keys && !is.null(records[[t]]$payload$scope) && canonical_json(p$scope) != canonical_json(records[[t]]$payload$scope)) add("SCOPE", key, "scope", paste("Scope differs from", t))
      }
    }
    if (x$kind == "evidence" && p$evidence_type == "computational") {
      for (target in p$execution_refs) {
        t <- ref_key(target)
        if (!t %in% keys || records[[t]]$kind != "execution") next
        run <- records[[t]]$payload
        if (run$reproduction_status != "passed" || any(vapply(run$output_refs, function(z) z$availability != "verified_local", logical(1)))) add("EVIDENCE", key, "execution_refs", "Computational evidence requires verified execution outputs")
        output_ids <- vapply(run$output_refs, function(z) paste(z$path, z$sha256), "")
        if (!any(vapply(p$source_refs, function(z) paste(z$path, z$sha256) %in% output_ids, logical(1)))) add("EVIDENCE", key, "source_refs", "Evidence source does not match referenced execution outputs")
      }
    }
    if (x$status == "accepted" && !x$kind %in% c("review", "change")) {
      dimension <- if (x$kind == "visualization_spec") "visual" else if (x$kind == "narrative_spec") "narrative" else "scientific"
      if (!reviewed(key, dimension)) add("REVIEW", key, "status", "Accepted revision lacks passing human review")
    }
    if (x$kind == "delivery") validate_delivery(x, key, records, graph, reviewed, add)
  }

  check_sets(bundle$candidate_refs, "bundle", add, "candidate_refs")
  for (key in keys) check_sets(records[[key]], key, add)
  dims <- unlist(bundle$adapter$required_review_dimensions)
  if (!identical(dims, sort(unique(c("scientific", "narrative", "visual", "reproducibility")), method = "radix"))) add("SCHEMA", "bundle", "adapter.required_review_dimensions", "All four sorted unique review dimensions are required")
  stale <- propagate_flags(stale, graph)
  for (key in keys[stale]) add("STALE", key, "dependencies", "Upstream bytes or selected revision changed", if (key %in% selected) "error" else "warning")
  blocked <- setNames(vapply(keys, function(key) any(vapply(findings, function(z) z$severity == "error" && z$record %in% c(key, "bundle"), logical(1))), logical(1)), keys)
  blocked <- propagate_flags(blocked, graph)
  states <- lapply(keys, function(key) {
    x <- records[[key]]; p <- x$payload
    implementation <- if (x$kind == "data_contract_ref") list(p$producer_ref) else if (x$kind == "metric") list(p$computation_ref) else if (x$kind == "execution") p$code_refs else list()
    list(identity = key, selected = key %in% selected,
      readiness = if (stale[[key]]) "stale" else if (blocked[[key]]) "blocked" else "ready",
      specified = TRUE,
      implemented = if (length(implementation)) all(vapply(implementation, function(z) {
        file <- safe_file(z$path, root)
        z$availability == "verified_local" && !is.null(file) && !is.null(z$sha256) &&
          digest::digest(file = file, algo = "sha256") == z$sha256
      }, logical(1))) else NULL,
      implementation_refs = implementation,
      executed = if (x$kind == "execution") !is.null(p$started_at) && !is.null(p$finished_at) && !is.null(p$exit_code) else NULL,
      execution_recorded = x$kind == "execution", execution_refs = if (x$kind == "evidence") p$execution_refs else list(),
      human_review_recorded = any(vapply(c("scientific", "narrative", "visual", "reproducibility"), function(d) reviewed(key, d), logical(1))),
      certified = FALSE)
  })
  finish(states)
}
