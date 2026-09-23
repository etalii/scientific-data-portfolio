# Accepted retrospective DataSpec dengue pilot

## Disposition and human authority

The requesting human accepted H01–H05 and H07/H09 within the documented scope,
and accepted H06/H08 with the exact proposed editorial changes. All nine are
now accepted after those changes were applied. The original `ACCEPT WITH EDIT`
dispositions remain recorded; they have not been replaced by unconditional
historical approval.

The preserved [user instruction](human_decision_request.txt) is the authority.
[Structured decisions](human_decisions.yml) retain the full scope, exact text,
and limitations. `requesting_user` is the least-assumptive role identifier;
`self` does not assert independent peer review. Actual application timestamps
are generated during closure, not inferred from historical analysis dates.

## Final artifacts and lifecycle

- [Accepted selected report fragment](../../../data/metadata/dataspec_rank_closure_v1/report_fragment.html).
- [Acceptance metadata](../../../data/metadata/dataspec_rank_closure_v1/acceptance.json).
- [Current 20-record bundle](../../../data/metadata/dataspec_rank_closure_v1/bundle.json).
- [Read-only validator result](../../../data/metadata/dataspec_rank_closure_v1/validation.json).
- [Post-review audit](../../../data/metadata/dataspec_rank_closure_v1/audit.json),
  [21 controls](../../../data/metadata/dataspec_rank_closure_v1/checks.json), and
  [negative checks](../../../data/metadata/dataspec_rank_closure_v1/mutation_checks.json).
- [Closure contract](../../../docs/dataspec_rank_closure_contract.md).

The final chain is question → plan → contracts/metrics → execution → evidence →
five qualified claims → narrative/visual specifications → human review → delivery.
There are 20 current records: the original 18-role chain with a new automated
review identity, plus `review_human` and `review_delivery`. The latter records
the user's explicitly conditional delivery acceptance and points to the delivery
without a circular dependency. The original 18-record bundle remains unchanged
as a separate, hashed historical snapshot. Unchanged question, plan, contracts
and metrics retain their exact revision-1 records. Changed records use revision 2.

The five claims, both specs and delivery use the implemented `accepted` status;
the delivery remains a `qualified_answer`. Unreviewed upstream authoring statuses
were not promoted. The validator reports a valid, ready chain with zero findings.
Its `certified: false` and scientific `not_assessed` semantics remain intact.
Project closure certifies only the documented technical checks plus bounded
human acceptance; it does not establish universal truth or independent review.

## Approved editorial implementation

The exact new introduction identifies selected contrasts and excludes reading
rank differences as temporal change or magnitude. The exact alt text identifies
24 jurisdictions including CABA and all four rank pairs; the corresponding HTML
`aria-label` is synchronized. The DataSpec caption now matches the existing PNG
caption literally after joining its display newline. PNG text, data, geometry,
highlighted jurisdictions, ranks and analytical values did not change.

The fragment is produced from the archived selected section through the configured
closure producer. The approved source is [accepted_report.qmd](accepted_report.qmd);
its remaining sections preserve source context and are outside pilot acceptance.
No full Quarto render is claimed. The historical report and QMD remain unchanged;
old wording in those archived artifacts is retained as evidence, not presented
as the current accepted deliverable. All limitations are visible in the new fragment.

## Validation and demonstrated reproducibility

- 48 common validator regression scenarios passed; common code/schemas unchanged.
- Six original dengue regression scenarios passed.
- Four closure-specific groups passed: reject altered decisions/unauthorized or
  ambiguous edits; retain human gates and stale propagation; preserve historical
  core records/claim values and exact specs; refuse overwriting immutable closure.
- All 21 post-review controls passed, both at build and read-only recheck.
- Six C.16 outputs reproduced byte-for-byte; all 24 denominators, rates,
  independently calculated ranks and geographic totals reconciled.
- The unchanged 2400×1800 PNG reproduced byte-for-byte and its embedded image
  matched. No guarantee across arbitrary operating systems is made.
- The selected narrative was checked against the independent ranks, archived
  statements and governed source expressions; the report was not rendered whole.
- All current external references and hashes resolved; the original bundle was
  replayed with its preserved pre-closure config and its nine historical gates.
- All 117 original file identities were preserved under the original additive
  configuration policy. Original v1 metadata was not overwritten.

The original PNG SHA-256 remains
`a7436545d8e9dc25b8b2efddf3488bef429dbe22de3a57d3aaf436820ad1be3f`.
The archived HTML remains
`12de3aa0d5a912304828e55fe99549b23d409c2cbfe4a6498617ea45f8e2d505`.
The new fragment is
`07d60803b8854912d979cbb52b180a6982163668d3eed0940a152a1a6984903d`.
These are different document identities, not an unexplained reproduction failure:
the new document includes only the selected section, approved edits, explicit
limitations and a standalone document wrapper.

## Retrospective and portability boundaries

The question and plan remain retrospectively reconstructed. No preregistration,
confirmatory hypothesis, original execution timestamp or historical approval was
invented. Current execution/application times describe actual new work. Available
ignored inputs are required; a bare Git checkout is not a complete data environment.

See [framework feedback](framework_feedback.md) for deferred observations. Common
skills are not stabilized from dengue alone. Climate work and push/publication
are outside this closure unit.
