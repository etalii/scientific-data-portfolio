# Executable validation contract v0.1.0

## Scope and input

`Rscript dataspec/validators/validate.R BUNDLE PROJECT_ROOT` reads a UTF-8 JSON
bundle and referenced files, then prints JSON to stdout. It never writes files,
executes a producer, downloads sources, or imports project code. Exit codes are
0 (structural/linkage validation passed), 1 (invalid/blocked/stale bundle), and
2 (invocation, parsing, schema configuration, or runtime failure).

The bundle schema is `schemas/bundle.schema.json`; standalone records use
`schemas/record.schema.json`. Bundles contain records for one project and study
(or framework changes), an exact candidate revision selection, and a declarative
adapter. Cross-project references are rejected in this minimum implementation.
The adapter supplies a hashed local scope schema and required review dimensions.
It cannot execute code or change validator rules. All four delivery review
categories remain mandatory. Synthetic fixtures are authored test inputs,
explicitly version-controlled; no real generated data is designated for Git.

## Schema profile and serialization

Schemas use the JSON Schema 2020-12 vocabulary subset implemented by the R
checker: `$ref` (local definitions only), `$defs`, `type`, `properties`,
`required`, `additionalProperties`, `propertyNames`, `items`, `minItems`,
`uniqueItems`, `minLength`, `pattern`, `minimum`, `enum`, `const`, `allOf`, and
`oneOf`. `$schema`, `$id`, `title`, and `description` are annotations. Unsupported
keywords, invalid references, or cyclic schema references are configuration
errors, never silently ignored. This checker is intentionally not a general
JSON Schema engine. The standalone record schema delegates to the bundle schema
for external tooling; the CLI uses the bundle schema directly.

Objects reject unknown fields except namespaced extensions. Empty arrays and
objects remain distinct; JSON object keys must be unique. JSON numbers representing
integers are accepted mathematically; strings are never coerced. Input key order
and record order do not affect results. Identity/reference sets are unique and
sorted by UTF-8 bytes; revision is compared numerically. Commands and narrative
sections preserve order. Internal-reference arrays are identity sets; external
reference arrays are unique sets sorted by path, hash, then locator. Review
dimensions are sorted unique strings. Other prose lists preserve their order.
Output uses stable sorting with no current timestamp.
SHA-256 describes file bytes, not JSON canonicalization. No record writer or
content-derived identity generator is introduced.

## Concrete refinements of the logical contracts

Nested fields are now typed in the schemas. Metric policies contain a rule and
an authority reference. Spatial applicability and denominator applicability are
explicit; a denominator is required for ratio/rate metrics. Scope is an object
validated against the adapter's schema. Metrics add a scope so evidence/claim
alignment can be checked. Equality is conservative: differing scopes block
acceptance; broader compatibility remains a future project-adapter capability.

Every record with empty limitations provides a nonempty `limitations_justification`
in its payload. Execution validation references are preserved external artifacts,
not internal reviews, avoiding execution/review cycles. Historical executions may
use null timestamps only with a gap reason and cannot claim passed reproduction.
Hypothesis timing includes an evidence-observation timestamp and preserved timing
references. Passing review still needs human judgment about their meaning.

A review targets exact revisions. A delivery includes exact narrative and visual
specifications, claim locations, artifacts, reviews, and the complete transitive
internal dependency snapshot (excluding itself). Every answer claim must be
supported or qualified as appropriate. Inconclusive deliveries explicitly explain
the gap and cannot promote unsupported claims as answers.

A framework bootstrap `change` may have no prior target. Other framework changes
reference the earlier records they affect. The project identifier `dataspec` is
reserved for changes; this exception introduces no domain-specific schema.

## Validation and state

All internal payload references and `depends_on` edges participate in the graph.
Duplicate identities, dangling references, cycles, wrong target kinds, missing
candidate selections, and mixed study identities block validation. One revision
per artifact is selected by `candidate_refs`; all referenced identities must be
present even when a newer revision is selected. Old revisions remain historical.

Files must resolve inside PROJECT_ROOT, including symlinks. Missing bytes and
hash mismatches block or stale affected records. Unavailable references remain
explicit warnings for drafts but cannot support an accepted record. A new
candidate revision makes consumers of the old revision stale; this propagates
transitively, including through reviews and delivery. Unrelated records remain
ready. No historical record bytes are changed.

Acceptance requires an accepted, selected, passing non-automated review of the
exact revision. A draft review cannot satisfy acceptance.
Claims require scientific review even when documentary sources exist. Deliveries
require scientific, narrative, visual, and reproducibility review of the exact
presentation specifications and delivered claims; final delivery acceptance has
its own review. Automated checks cannot certify interpretation. Reviews do not
require recursively reviewing themselves. Independent reviewers cannot be the
owner of a target record. Supersession must link the same artifact's earlier
revision; accepted historical records are not rewritten.

Reports distinguish specified records, implementation file evidence, execution
records, and recorded human review. `certified` is always false in this minimal
validator: passing linkage checks does not verify truth, reproduce analysis,
confirm reviewer identity, inspect visual rendering, or establish independent
scientific certification. Stage properties include the supporting record/file
references and unknowns rather than treating implementation presence as execution.
`implemented` means the declared producer files exist with matching hashes;
`executed` means an execution record supplies timestamps and an exit code. These
are bounded observations of supplied records, not independent confirmations that
code ran. Fields without applicable evidence are null rather than invented.

## Error families

- `SCHEMA`: JSON shape, type, vocabulary, conditional requirement, or set order.
- `IDENTITY`, `REFERENCE`, `CYCLE`: identity, graph, kind, or selection error.
- `PATH`, `HASH`, `UNAVAILABLE`: external artifact integrity or availability.
- `SCOPE`, `DENOMINATOR`, `TIMING`: semantic prerequisites.
- `EVIDENCE`, `CLAIM`, `REVIEW`, `DELIVERY`: acceptance/traceability prerequisites.
- `STALE`: upstream bytes or selected revision changed.

Each finding identifies severity, record identity, field/path, and a message.
Errors and stale candidates make the CLI exit nonzero. Warnings remain visible.
Hash and structural checks are not a substitute for reading sources or artifacts.

## Environment and verification

Run with R 4.1 or later, jsonlite 2.0.0 and digest 0.6.39 (the tested versions).
`DESCRIPTION` and `renv.lock` describe the isolated DataSpec environment; existing
project environments are untouched. No package installation is performed by the
validator. Restore deliberately with renv if those dependencies are unavailable.
The base-R test harness uses temporary directories for fault injection and checks
that all fixture bytes remain unchanged. Run it from the portfolio root with
`Rscript dataspec/tests/run_tests.R`.
