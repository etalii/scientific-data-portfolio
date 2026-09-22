# Adoption plan and acceptance criteria

## Slice 0: reviewable architecture (delivered)

Outputs: architecture, minimum logical contracts, initial project inventory,
upstream attribution, and this ordered plan. Acceptance criteria:

- Common and project-specific ownership are explicit.
- Existing contracts/configuration retain authority and are referenced.
- Retrospective and prospective work are distinguishable.
- Evidence, scientific judgment, implementation, and certification are distinct.
- Both pilots have bounded scope and measurable closure criteria.
- Documentation links resolve and no project artifacts are modified.

## Slice 1: executable minimum

Implemented on 2026-09-22: [schemas](schemas/bundle.schema.json), a read-only
[R validator](validators/validate.R), [synthetic regression tests](tests/run_tests.R),
and [authoring starters](templates/README.md). The following acceptance scope is
retained for traceability. The [validation contract](validation_contract.md)
documents the exact supported subset and limitations; no scientific certification
or project migration is implied.

Encode the logical contracts as versioned schemas, minimal templates, and an R
validator. Specify nested types, serialization, error codes, configured output
paths, and any versioned-provenance exceptions before adding writers. Review
schema dependencies against the existing R environments; introduce dependencies
only through the repository's environment-management rules.

Begin with a synthetic descriptive study linking a question, plan, contract,
metric, execution, evidence, claim, chart, narrative, review, and delivery.
Add documentary and inconclusive cases. Use behavior-focused tests with failing
cases first for validators and change propagation; no tests for prose wording.

Required negative fixtures: duplicate ID, missing reference, cycle, changed
input hash, mismatched scope, missing denominator definition where required,
unsupported claim presented as supported, retrospective hypothesis presented
as pre-specified, missing review, and stale downstream delivery. Add a case where
a documentary source exists but does not support the claimed interpretation;
the automatic system must require scientific review rather than certify it.

Closure requires deterministic validation results, actionable failures, no
mutations by the validator, and no dependence on either project's vocabulary.

## Slice 2: retrospective dengue pilot

Scope: the calendar-year 2024 provincial count/rate rank-change claim, contemporary
denominator scenario, its existing C.20 figure, and associated report prose.
Scope excludes seasonal analysis, new indicators, rewriting the report, and
publication. Keep all domain-specific pilot records within the dengue project.

1. Record the baseline Git revision, relevant working-tree differences, and
   hashes of governing contracts, configuration, inputs, figure, and report.
2. Locate the exact C.16 producer outputs and existing validation evidence.
   Establish availability before claiming an execution is reproducible.
3. Register semantic references and reconstruct the question/plan from available
   records. Label reconstructed decisions retrospective; list unknown history.
4. Link the claim to exact rows, metric definitions, producer, environment,
   validation, chart specification, and report locations.
5. Conduct scientific, narrative, visual, and reproducibility reviews. If a
   reproduction run is needed, use an isolated output location/workspace; never
   overwrite certified baseline files to establish equivalence.

| Acceptance criterion | Required evidence |
| --- | --- |
| Exact claim supported | Rank values reconciled with identified rows, denominator scenario, eligibility, and tie/order rules. |
| Scope preserved | Calendar-year 2024 explicitly distinguished from seasonal scopes in claim, chart, and report mapping. |
| Meaning preserved | Published-count rates remain descriptive; wording does not imply incidence or individual risk. |
| Complete linkage | Every selected substantive statement and visual resolves to exact evidence and governing definitions. |
| Honest historical reconstruction | Origin labels and timing evidence distinguish recovered history from current reconstruction. |
| Honest reproducibility status | Existing execution evidence or an isolated reproduction is checked; missing evidence produces an explicit blocked/qualified outcome. |
| Change propagation | A synthetic modified input marks affected evidence/claims/delivery stale while unrelated records remain unaffected. |
| Baseline integrity | Before/after hashes of protected inputs and deliverables match; no raw acquisition or publication occurs. |
| Reviewed outcome | Exact revisions and reviewer modes recorded; unresolved gaps cannot be labeled a fully certified answer. |

If evidence cannot be recovered, close the pilot as a documented traceability
gap with remediation tasks. This is not full acceptance of the traced claim.

## Slice 3: climate portability and prospective use

Select one ordered baseline/future semantic-comparability review after inventory
reconciliation. Use its governed documentary and structural references; include
value-check evidence only when available and within its contract. Do not create
a biodiversity outcome or causal climate claim for the sake of a story.

First reconstruct the existing review state retrospectively. Then register the
next unresolved methodological question and evaluation rule prospectively before
new analysis. Link the new result and its limits to a small narrative/visual spec
only if communication is warranted; non-applicability needs an explicit reason.

Acceptance requires distinguishing documentary support, structural observations,
and sampled values; preserving existing eligibility rules; representing unresolved
or inconclusive outcomes; and using the same common schemas without adding
climate-specific fields to the core. Project extensions must be namespaced.
Missing executions remain visible instead of inheriting certification from a
contract. Reconcile the project README only after this status assessment.

## Slice 4: skills, evaluations, and distribution

Implement only skill responsibilities demonstrated as missing by both pilots.
Reuse existing specialist skills. Add a lifecycle entry point, explicit input
and output contracts, focused references, and positive/negative trigger cases.
Use the applicable skill-creation workflow when creating these files.

Pin any adopted upstream implementation by commit and retain required notices.
Evaluate the external installer on a controlled target before making it part of
the setup instructions. Maintain one authoritative copy of each common skill.
Do not introduce automatic updates to scientific operating procedures.

The complete framework becomes operational only when a new bounded study can be started,
validated, reviewed, and handed off through documented commands and available
skills, and both project pilots demonstrate those commands. The minimum validator
does not claim that complete operational milestone.

## Session hand-off

Each future change must leave a durable record of scope, exact dependencies,
completed work, checks actually run, unresolved decisions, and the next bounded
action. A new session reads those records and applicable instructions. Chat
history can help locate context but is not the sole authority for scientific
decisions, approval history, or certification.
