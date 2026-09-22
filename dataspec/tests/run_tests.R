# DataSpec synthetic regression tests.
# Inputs: authored fixture bundle and local assets. Outputs: console results only.
# All fault injection occurs in an isolated temporary project directory.

source("dataspec/validators/core.R")
fixture_root <- "dataspec/tests/fixtures/minimal"
schema_path <- "dataspec/schemas/bundle.schema.json"
baseline <- read_json_strict(file.path(fixture_root, "bundle.json"))

# Return a named artifact's index in a bundle.
record_index <- function(bundle, id) {
  which(vapply(bundle$records, function(x) x$artifact_id == id, logical(1)))
}

# Apply one mutation and assert a diagnostic, preserving the valid fixture.
expect_error <- function(name, code, mutate) {
  bundle <- mutate(baseline)
  result <- validate_bundle(bundle, fixture_root, schema_path)
  stopifnot(!result$valid, code %in% vapply(result$findings, `[[`, "", "code"))
  cat("PASS", name, "\n")
}

result <- validate_bundle(baseline, fixture_root, schema_path)
stopifnot(result$valid)
cat("PASS valid computational study\n")
expect_error("duplicate identity", "IDENTITY", function(b) {
  b$records <- c(b$records, b$records[1]); b
})
expect_error("dangling reference", "REFERENCE", function(b) {
  i <- record_index(b, "claim")
  b$records[[i]]$payload$question_ref$artifact_id <- "absent"; b
})
expect_error("cycle", "CYCLE", function(b) {
  i <- record_index(b, "question")
  b$records[[i]]$depends_on <- list(list(project_id="synthetic", artifact_id="claim", revision=1L)); b
})
expect_error("scope mismatch", "SCOPE", function(b) {
  i <- record_index(b, "claim"); b$records[[i]]$payload$scope$period <- "2025"; b
})
expect_error("missing denominator", "DENOMINATOR", function(b) {
  i <- record_index(b, "metric"); b$records[[i]]$payload$denominator$definition_ref <- NULL; b
})
expect_error("unsupported answer", "CLAIM", function(b) {
  i <- record_index(b, "claim"); b$records[[i]]$payload$disposition <- "unsupported"; b
})
expect_error("missing scientific review", "REVIEW", function(b) {
  i <- record_index(b, "review"); b$records[[i]]$payload$review_mode <- "automated"; b
})
expect_error("unknown field", "SCHEMA", function(b) {
  b$records[[1]]$unknown <- TRUE; b
})
expect_error("string revision", "SCHEMA", function(b) {
  b$records[[1]]$revision <- "1"; b
})
expect_error("path traversal", "PATH", function(b) {
  i <- record_index(b, "execution"); b$records[[i]]$payload$input_refs[[1]]$path <- "../outside.csv"; b
})
expect_error("input hash mismatch", "HASH", function(b) {
  i <- record_index(b, "execution"); b$records[[i]]$payload$input_refs[[1]]$sha256 <- paste(rep("0",64),collapse=""); b
})
expect_error("successful exit without validation", "EVIDENCE", function(b) {
  i <- record_index(b, "execution"); b$records[[i]]$payload$validation_refs <- list(); b
})


# Add an artifact and its selected revision, maintaining reference-set ordering.
append_record <- function(bundle, record) {
  bundle$records <- c(bundle$records, list(record))
  reference <- record[c("project_id", "artifact_id", "revision")]
  bundle$candidate_refs <- c(bundle$candidate_refs, list(reference))
  bundle$candidate_refs <- bundle$candidate_refs[order(vapply(bundle$candidate_refs, ref_key, ""), method = "radix")]
  bundle
}

# Construct a synthetic hypothesis with verifiable or deliberately absent timing.
with_hypothesis <- function(bundle, timing = TRUE) {
  record <- bundle$records[[record_index(bundle, "question")]]
  record$artifact_id <- "hypothesis"; record$kind <- "hypothesis"
  record$payload <- list(question_ref = list(project_id="synthetic",artifact_id="question",revision=1L),
    statement="Group b has the higher rate.", hypothesis_type="confirmatory",
    formulated_at="2026-01-01T00:00:00Z", results_observed_at="2026-01-02T00:00:00Z",
    timing_evidence_refs=if (timing) list(baseline$records[[record_index(baseline,"contract")]]$payload$document_ref) else list(),
    evaluation_rule="Compare exact rates.")
  append_record(bundle, record)
}
stopifnot(validate_bundle(with_hypothesis(baseline), fixture_root, schema_path)$valid)
cat("PASS retrospective registration with preserved pre-specification evidence\n")
expect_error("retrospective hypothesis without timing evidence", "TIMING", function(b) with_hypothesis(b,FALSE))
expect_error("hypothesis after observation", "TIMING", function(b) {
  b <- with_hypothesis(b)
  i <- record_index(b,"hypothesis"); b$records[[i]]$payload$formulated_at <- "2026-01-03T00:00:00Z"; b
})

documentary <- baseline
i <- record_index(documentary,"evidence")
documentary$records[[i]]$payload$evidence_type <- "documentary"
documentary$records[[i]]$payload$execution_refs <- list()
documentary$records[[i]]$payload$source_refs <- list(list(path="assets/source.txt",
  sha256=digest::digest(file=file.path(fixture_root,"assets/source.txt"),algo="sha256"),
  locator="whole file",availability="verified_local"))
documentary$records <- Filter(function(x) !x$artifact_id %in% c("execution","plan"),documentary$records)
documentary$candidate_refs <- Filter(function(x) !x$artifact_id %in% c("execution","plan"),documentary$candidate_refs)
j <- record_index(documentary,"delivery")
documentary$records[[j]]$payload$dependency_snapshot <- Filter(function(x) !x$artifact_id %in% c("execution","plan"),documentary$records[[j]]$payload$dependency_snapshot)
stopifnot(validate_bundle(documentary, fixture_root, schema_path)$valid)
cat("PASS documentary evidence with human review\n")
no_review <- documentary
no_review$records[[record_index(no_review,"review")]]$payload$disposition <- "revise"
stopifnot(!validate_bundle(no_review, fixture_root, schema_path)$valid)
cat("PASS existing document alone cannot establish claim support\n")

inconclusive <- baseline
i <- record_index(inconclusive,"claim"); inconclusive$records[[i]]$payload$disposition <- "inconclusive"
i <- record_index(inconclusive,"delivery")
inconclusive$records[[i]]$payload$delivery_disposition <- "inconclusive"
inconclusive$records[[i]]$payload$inconclusive_reason <- "Insufficient support for a substantive answer."
stopifnot(validate_bundle(inconclusive, fixture_root, schema_path)$valid)
cat("PASS explicit inconclusive outcome\n")

changed <- baseline
i <- record_index(changed,"metric")
new <- changed$records[[i]]; new$revision <- 2L
new$supersedes <- new[c("project_id","artifact_id","revision")]; new$supersedes$revision <- 1L
changed$candidate_refs <- Filter(function(x) x$artifact_id != "metric", changed$candidate_refs)
changed <- append_record(changed,new)
changed_result <- validate_bundle(changed,fixture_root,schema_path)
readiness <- setNames(vapply(changed_result$records, `[[`, "", "readiness"), vapply(changed_result$records, `[[`, "", "identity"))
stopifnot(!changed_result$valid,
  readiness[["synthetic/claim/000000000001"]] == "stale",
  readiness[["synthetic/delivery/000000000001"]] == "stale",
  readiness[["synthetic/unrelated/000000000001"]] == "ready",
  readiness[["synthetic/metric/000000000002"]] == "ready")
cat("PASS revision change propagates staleness only to dependents\n")

# Test physical byte changes and filesystem boundaries in a disposable copy.
sandbox <- tempfile("dataspec_test_"); dir.create(sandbox)
invisible(file.copy(list.files(fixture_root, full.names=TRUE), sandbox, recursive=TRUE))
files <- list.files(sandbox,recursive=TRUE,full.names=TRUE)
# Compute byte identities for a fixed list of fixture files.
hash_files <- function(paths) vapply(paths,function(p) digest::digest(file=p,algo="sha256"),"")
before <- hash_files(files)
first <- validate_bundle(baseline,sandbox,schema_path)
second <- validate_bundle(baseline,sandbox,schema_path)
stopifnot(identical(first,second),identical(before,hash_files(files)))
cat("PASS deterministic read-only validation\n")
cat("tampered\n",file=file.path(sandbox,"assets/observations.csv"),append=TRUE)
tampered <- validate_bundle(baseline,sandbox,schema_path)
state <- setNames(vapply(tampered$records,`[[`,"","readiness"),vapply(tampered$records,`[[`,"","identity"))
stopifnot(state[["synthetic/delivery/000000000001"]] == "stale", state[["synthetic/unrelated/000000000001"]] == "ready")
cat("PASS physical input change invalidates downstream delivery\n")
outside <- tempfile("dataspec_external_"); writeLines("outside",outside)
unlink(file.path(sandbox,"assets/observations.csv"))
stopifnot(file.symlink(outside,file.path(sandbox,"assets/observations.csv")))
escaped <- validate_bundle(baseline,sandbox,schema_path)
stopifnot("PATH" %in% vapply(escaped$findings,`[[`,"","code"))
cat("PASS symlink escape rejected\n")
unlink(sandbox,recursive=TRUE); unlink(outside)

reordered <- baseline; reordered$records <- rev(reordered$records)
stopifnot(identical(validate_bundle(baseline,fixture_root,schema_path),validate_bundle(reordered,fixture_root,schema_path)))
cat("PASS record order does not affect report\n")

# Duplicate JSON keys and unsupported schema keywords must fail explicitly.
malformed <- tempfile(fileext=".json"); writeLines('{"same":1,"same":2}',malformed)
stopifnot(inherits(try(read_json_strict(malformed),silent=TRUE),"try-error")); unlink(malformed)
stopifnot(inherits(try(check_schema_profile(list(type="object",unsupported=TRUE)),silent=TRUE),"try-error"))
cat("PASS duplicate keys and unsupported schema profile rejected\n")


expect_error("unavailable source cannot support delivery", "UNAVAILABLE", function(b) {
  i <- record_index(b,"evidence")
  b$records[[i]]$payload$source_refs[[1]]$availability <- "unavailable"
  b$records[[i]]$payload$source_refs[[1]]$reason <- "Historical source missing."
  b
})
expect_error("draft review cannot support delivery", "REVIEW", function(b) {
  b$records[[record_index(b,"review")]]$status <- "draft"; b
})
expect_error("wrong reference kind", "REFERENCE", function(b) {
  b$records[[record_index(b,"claim")]]$payload$question_ref$artifact_id <- "metric"; b
})
expect_error("mixed study", "IDENTITY", function(b) {
  b$records[[record_index(b,"claim")]]$study_id <- "another_study"; b
})
expect_error("extra snapshot entry", "DELIVERY", function(b) {
  i <- record_index(b,"delivery")
  refs <- c(b$records[[i]]$payload$dependency_snapshot,list(list(project_id="synthetic",artifact_id="unrelated",revision=1L)))
  b$records[[i]]$payload$dependency_snapshot <- refs[order(vapply(refs,ref_key,""),method="radix")]; b
})
expect_error("narrative hidden claim", "DELIVERY", function(b) {
  b$records[[record_index(b,"narrative")]]$payload$ordered_sections[[1]]$claim_refs <- list(); b
})
expect_error("false independent review", "REVIEW", function(b) {
  b$records[[record_index(b,"review")]]$payload$reviewer <- "analyst"; b
})
expect_error("impossible date", "SCHEMA", function(b) {
  b$records[[1]]$created_at <- "2026-02-30T00:00:00Z"; b
})
expect_error("unordered reference set", "SCHEMA", function(b) {
  b$candidate_refs <- rev(b$candidate_refs); b
})
expect_error("missing candidate selection", "REFERENCE", function(b) {
  b$candidate_refs <- b$candidate_refs[-1]; b
})
expect_error("causal claim without authorization", "CLAIM", function(b) {
  b$records[[record_index(b,"claim")]]$payload$claim_type <- "causal"; b
})
expect_error("unknown schema version", "SCHEMA", function(b) {
  b$schema_version <- "0.2.0"; b
})
expect_error("inconclusive delivery lacks explanation", "DELIVERY", function(b) {
  b$records[[record_index(b,"delivery")]]$payload$delivery_disposition <- "inconclusive"; b
})
expect_error("review with unresolved check", "REVIEW", function(b) {
  b$records[[record_index(b,"review")]]$payload$checks[[1]]$result <- "unresolved"; b
})

# Exercise the change record and null-study framework exception separately.
framework <- baseline
change <- framework$records[[1]]
change$project_id <- "dataspec"; change["study_id"] <- list(NULL)
change$artifact_id <- "change"; change$kind <- "change"; change$depends_on <- list()
change$payload <- list(reason="Exercise framework change.",target_refs=list(list(project_id="dataspec",artifact_id="earlier",revision=1L)),impact="Synthetic only.",tasks=list("Review change."),required_checks=list("Schema validation."),closure_refs=list())
earlier <- change; earlier$artifact_id <- "earlier"
earlier$payload$target_refs <- list()
# A framework bootstrap change may start with no previous target.
framework$adapter$project_id <- "dataspec"
framework$records <- list(change,earlier)
framework$candidate_refs <- lapply(framework$records,function(x) x[c("project_id","artifact_id","revision")])
stopifnot(validate_bundle(framework,fixture_root,schema_path)$valid)
framework$records[[2]]$payload$target_refs <- list(list(project_id="dataspec",artifact_id="earlier",revision=1L))
stopifnot("CYCLE" %in% vapply(validate_bundle(framework,fixture_root,schema_path)$findings,`[[`,"","code"))
cat("PASS framework bootstrap and self-cycle rejection\n")

# CLI reports are JSON, work from another directory, and use documented exit codes.
cli <- normalizePath("dataspec/validators/validate.R")
fixture_absolute <- normalizePath(fixture_root)
stdout <- tempfile(); stderr <- tempfile()
old_directory <- getwd(); setwd(tempdir())
status <- system2(file.path(R.home("bin"),"Rscript"),c(shQuote(cli),shQuote(file.path(fixture_absolute,"bundle.json")),shQuote(fixture_absolute)),stdout=stdout,stderr=stderr)
setwd(old_directory)
stopifnot(status == 0L,read_json_strict(stdout)$valid)
status <- system2(file.path(R.home("bin"),"Rscript"),shQuote(cli),stdout=stdout,stderr=stderr)
stopifnot(status == 2L)
unlink(c(stdout,stderr))
cat("PASS CLI works outside repository and rejects missing arguments\n")

expect_error("empty supporting evidence", "CLAIM", function(b) {
  b$records[[record_index(b,"claim")]]$payload$supporting_evidence_refs <- list(); b
})
expect_error("null where string required", "SCHEMA", function(b) {
  b$records[[record_index(b,"claim")]]$payload["claim_text"] <- list(NULL); b
})
expect_error("duplicate external reference", "SCHEMA", function(b) {
  i <- record_index(b,"execution")
  b$records[[i]]$payload$input_refs <- rep(b$records[[i]]$payload$input_refs,2); b
})
expect_error("review predates target", "TIMING", function(b) {
  b$records[[record_index(b,"review")]]$payload$reviewed_at <- "2025-01-01T00:00:00Z"; b
})
expect_error("unavailable verified hash", "SCHEMA", function(b) {
  b$records[[record_index(b,"execution")]]$payload$input_refs[[1]]["sha256"] <- list(NULL); b
})
expect_error("scope schema enforced", "SCOPE", function(b) {
  b$records[[record_index(b,"question")]]$payload$scope$extra <- "unexpected"; b
})

failed_cli_bundle <- tempfile(fileext=".json")
invalid <- baseline; invalid$records[[1]]$unexpected <- TRUE
writeLines(jsonlite::toJSON(invalid,auto_unbox=TRUE,null="null",pretty=TRUE),failed_cli_bundle)
stdout <- tempfile(); stderr <- tempfile()
status <- system2(file.path(R.home("bin"),"Rscript"),c(shQuote(cli),shQuote(failed_cli_bundle),shQuote(fixture_absolute)),stdout=stdout,stderr=stderr)
stopifnot(status == 1L, !read_json_strict(stdout)$valid)
writeLines('{"broken":',failed_cli_bundle)
status <- system2(file.path(R.home("bin"),"Rscript"),c(shQuote(cli),shQuote(failed_cli_bundle),shQuote(fixture_absolute)),stdout=stdout,stderr=stderr)
stopifnot(status == 2L)
unlink(c(failed_cli_bundle,stdout,stderr))
cat("PASS CLI distinguishes invalid bundles from malformed JSON\n")
cat("All DataSpec regression scenarios passed.\n")
