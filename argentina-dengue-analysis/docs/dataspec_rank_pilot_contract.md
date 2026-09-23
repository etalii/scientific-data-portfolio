# Retrospective DataSpec provincial rank pilot

## Identity and scope

Contract ID: `dataspec_rank_pilot`. Version: `1.0.0`.

This additive contract implements DataSpec adoption slice 2, authorized by the
request to execute the retrospective dengue pilot. It checks the existing
calendar-year 2024 provincial count/rate ranking under the contemporary
population-denominator scenario. It does not change C.16, C.20, the scientific
configuration, existing figures, or the published report. Season-level and
regional conclusions are outside the claim review.

## Ownership and producers

- `scripts/validation/21_audit_dataspec_rank_pilot.R` owns the audit provenance
  directory. It reads the baseline manifest/configuration, reproduces C.16 and
  the selected C.20 figure in a disposable isolated directory, compares bytes,
  reconciles rates/ranks and report locations, and publishes audit metadata.
- `scripts/processing/22_build_dataspec_rank_trace.R` owns `bundle.json`,
  `validation.json`, and `mutation_checks.json` within that audit directory.
  It registers the completed audit in the common DataSpec schema, records the
  assistant review explicitly as automated, and checks traceability/staleness.
- The study README and review are human-readable, assistant-authored records.
  They are not human approval or independent scientific certification.

All configurable paths and scope choices come from `config/project.yml`.
The only script bootstrap path is `config/project.yml`. The original analytical
configuration is compared after removing only `dataspec_rank_pilot`.

## Inputs and baseline

Capture the exact Git revision, UTC capture time, tracked project differences,
and the path, SHA-256, and byte size of existing files under config, raw,
processed, reference, metadata, figures, reports, docs, and scripts, plus
README, AGENTS, DESCRIPTION, and renv.lock. The baseline configuration is a
byte-preserving provenance snapshot, not a second operational configuration.
The initial snapshots may be passed as CLI paths; they are verified before use.
Do not infer execution dates from filesystem mtimes or reconstruct approval
history from absent logs.

C.16 consumes the seven already-governed inputs listed by its contract. Its six
outputs are regenerated only in an isolated workspace and compared against all
six existing outputs. No source acquisition or C.1-C.15 rerun occurs. Original
raw-file hashes are included in the preservation check, without rereading their
observations for analysis. A matching reproduction certifies only the bounded
C.16 computation from available inputs, not the upstream acquisition process.

C.20's rank function and plot builder are sourced without running their main
entrypoint. Independently ordered ranks are compared using descending value and
reference province ID, and the selected English PNG is rendered in isolation.
Its signature, dimensions, and bytes are compared with the existing figure.
No whole-report render or deployment is performed.

## Required checks

1. All protected baseline files retain their bytes. Only the additive
   configuration extension is permitted; its prior bytes remain snapshotted.
2. The selected C.16 input has 24 unique province IDs, one source year, scope,
   contemporary scenario, expected population vintage/date and period basis.
3. Denominators match the governed C.14 province/year/vintage rows, and rates
   reconcile to `100000 * published_case_count / province_population` within the
   configured tolerance. Geographic eligibility and mapped totals reconcile
   with C.15; unknown geography is not redistributed.
4. All four featured provinces satisfy existing C.20 expected rank pairs. Those
   expectations check computed ranks; they never generate the observed ranks.
5. The report's source and rendered selected section contain the corresponding
   values, scope, figure location, and interpretation limits. The embedded PNG
   bytes match the governed figure. Source locators are explicit in the bundle.
6. C.16 reproduction and the selected C.20 rerender match their baseline bytes.
7. An in-memory input-hash mutation makes the related evidence, claims, and
   delivery stale; the question remains unaffected. This test edits no source.
8. Common validation has no schema, identity, reference, path, hash, scope,
   denominator, timing, evidence, claim, delivery, or stale errors on real records.
   `REVIEW` errors are expected while human approval has not been recorded.

If any mechanical check fails, do not silently promote the claim or alter the
baseline. Publish no successful audit; preserve the baseline and report the
failure. Scientific/visual judgment and human approval remain explicit.

## Output schemas and tracking

The audit directory is an immutable, version-controlled provenance exception.
It contains only the following explicitly designated metadata, not copies of
analytical data tables or regenerated figures:

- `baseline.json`: baseline Git/time/diff plus ordered file identities.
- `baseline_project.yml`: exact historical configuration bytes.
- `environment.json`: R/platform and named installed package versions, current
  code identities, and the common framework Git baseline.
- `checks.json`: ordered `{check_id, status, detail}` checks with pass/fail status.
- `audit.json`: contract/version, UTC start/end, command, input identities,
  C.16 output comparison identities, selected PNG comparison, the four featured
  rank-check results, scope, bounded reproduction status, and historical gaps.
- `bundle.json`: DataSpec `0.1.0` bundle with retrospective-origin records and
  project-local semantic scope schema. Current audit execution dates are real;
  no date or human review is invented for the historical analysis.
- `validation.json`: exact deterministic common-validator result for that bundle.
- `mutation_checks.json`: baseline/mechanical validation results and the bounded
  in-memory hash-mutation findings.

JSON uses UTF-8, two-space indentation, a final newline, explicit nulls, stable
field order, and sorted identity/reference arrays where required by DataSpec.
File hashes describe exact bytes. Records follow the common schema; audit field
structures are constructed explicitly by the owning script and consumed by the
trace producer. Four featured expected/observed rank records are retained solely
as reconciliation evidence, not as a replacement analytical table.

A producer validates its inputs before writing. Initial audit publication uses
a temporary sibling directory and atomic rename. Existing output identities
are never overwritten; reruns must use a new configured directory/revision or
independently reproduce in temporary storage. Trace metadata is staged and
validated before publication; partial new files are rolled back on failure.

## Review disposition

The pilot can finish its computational and traceability work with a qualified
result while a delivery remains blocked on human review. Do not relabel the
assistant as a human, set `review_mode` to self/independent for an automated
review, weaken the common validator, or claim that a link/hash proves scientific
truth. The registered narrative/visual specs describe the existing selected
section; they do not certify the remainder of the report.
