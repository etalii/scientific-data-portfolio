# Retrospective DataSpec pilot: provincial rank shifts

**Current outcome: accepted qualified delivery after explicit human review.**

The 2026-09-23 closure preserves the original audit below and publishes a new
[accepted report fragment](../../../data/metadata/dataspec_rank_closure_v1/report_fragment.html),
[current bundle](../../../data/metadata/dataspec_rank_closure_v1/bundle.json),
[acceptance record](../../../data/metadata/dataspec_rank_closure_v1/acceptance.json),
and [validation](../../../data/metadata/dataspec_rank_closure_v1/validation.json).
The final chain has 20 records, including two explicit human review records;
all nine requirements are resolved. Claims and delivery remain qualified.
See [closure notes](closure.md), [human decisions](human_decisions.yml), and
[deferred framework feedback](framework_feedback.md).

## Original audit, preserved as history

The following documents the initial technical audit before human acceptance.
Executed on 2026-09-22 against Git baseline
`2550b91927db1a49e5fbbf6fa0facb092dc74ecb` after that baseline was pushed to GitHub.
All registered analytical questions/plans/specifications are retrospective.

## Bounded result

Calendar year 2024, contemporary denominator scenario, 24 mapped INDEC
jurisdictions. The four existing featured provincial rank statements reconcile:

| Province | Published-count rank | Published-count-rate rank |
| --- | --- | --- |
| Buenos Aires | 1 | 16 |
| Tucuman | 3 | 1 |
| La Rioja | 12 | 2 |
| Catamarca | 13 | 4 |

These are descriptive published-count indicators. They are not incidence,
unique-person counts, causal effects, or individual risk. Territorial numerators
exclude unknown/nonassignable geography without redistribution. The separate
SE31/2024-SE30/2025 season is not part of this claim review.

## Evidence and verification

- **21 mechanical checks passed.** The existing C.16 producer recreated all six
  indicators byte-for-byte from its seven governed inputs in temporary storage.
- All 24 provincial denominators match C.14 and all rates reconcile to the
  contractual formula. Mapped totals and eligibility reconcile to C.15.
- Independently computed ranks agree with C.20 and the selected rendered report
  section. The selected English PNG rerender is byte-identical to the existing
  figure; its HTML-embedded copy has the same bytes.
- **117 original file identities were preserved.** The original configuration
  bytes are snapshotted; the sole intentional change to an existing protected
  file is the additive `dataspec_rank_pilot` configuration. No raw acquisition,
  existing indicator/figure/report replacement, or publication occurred.
- **18 DataSpec records** link the question, three contracts, two metrics, plan,
  current audit execution, evidence, five claims, narrative/visual specs,
  automated review, and proposed delivery.
- Mechanical validation passes when considering the records before delivery.
  The full delivery correctly returns **9 `REVIEW` findings**, representing
  missing human review for five claims and four narrative/visual/reproducibility
  requirements. No other validation error occurs.
- An in-memory input-hash mutation marks evidence, a claim, and delivery stale,
  while the question remains ready. No input bytes were changed for this test.
- Six project regression scenarios passed, covering large-HTML extraction,
  missing/truncated sections, unapproved configuration changes, wrong province
  cardinality, refusal to overwrite both metadata sets, and baseline integrity.

The installed package versions used by the audit match the corresponding
project `renv.lock` entries. Original C.16/C.20 execution timestamps and historical
human approvals were not recovered; actual new reproduction times are recorded.
This establishes bounded reproduction from the available governed inputs, not
recertification of the source acquisition or the entire published report.

## Artifacts

The [pilot contract](../../../docs/dataspec_rank_pilot_contract.md) designates
these files as version-controlled provenance metadata, without tracking generated
analysis tables or rerendered figures:

- [Baseline file identities](../../../data/metadata/dataspec_rank_pilot_v1/baseline.json)
  and [historical configuration](../../../data/metadata/dataspec_rank_pilot_v1/baseline_project.yml).
- [Execution and reproduction audit](../../../data/metadata/dataspec_rank_pilot_v1/audit.json),
  [checks](../../../data/metadata/dataspec_rank_pilot_v1/checks.json), and
  [environment](../../../data/metadata/dataspec_rank_pilot_v1/environment.json).
- [DataSpec bundle](../../../data/metadata/dataspec_rank_pilot_v1/bundle.json),
  [validation](../../../data/metadata/dataspec_rank_pilot_v1/validation.json), and
  [mutation checks](../../../data/metadata/dataspec_rank_pilot_v1/mutation_checks.json).
- [Assistant review](review.md), explicitly recorded as automated, and
  [project-local scope schema](scope.schema.json).

## Recheck the accepted pilot

From `argentina-dengue-analysis/`:

```bash
Rscript --vanilla tests/validation/test_dataspec_rank_pilot.R
Rscript --vanilla tests/validation/test_dataspec_rank_closure.R
Rscript --vanilla scripts/processing/23_close_dataspec_rank_pilot.R --check
Rscript --vanilla ../dataspec/validators/validate.R data/metadata/dataspec_rank_closure_v1/bundle.json .
```

All commands must return 0. The closure recheck independently repeats the 21
controls and exact C.16/PNG reproduction in temporary storage. It also replays
the original bundle with `pre_closure_project.yml`, preserving its nine historical
REVIEW findings. Directly validating the old bundle against today's extended
configuration correctly flags its old configuration hash; do not rewrite that
bundle to conceal the configuration revision.

Available ignored analytical inputs and the verified R environment are required;
a Git clone alone is insufficient. The producer refuses to overwrite closure
identities. To repeat initial publication, use an isolated copy, retain all
historical inputs, and configure a new closure directory. Actual run/application
times must be retained. Original audit producers 21/22 remain unchanged.

## Acceptance boundary and next use

The human accepted H01–H05 and H07/H09 within their recorded scope; H06/H08 were
accepted only after the exact approved edits. The reviewer role is
`requesting_user`, mode `self`; no personal name or independent peer-review
identity is inferred. Applied timestamps describe this present application.

The accepted delivery contains only the selected revised HTML section and the
unchanged English PNG. The archived whole report remains historical and was not
rerendered, replaced, republished, or accepted as a whole. Its old wording is
retained solely as provenance. The source of the accepted text is
`accepted_report.qmd`; remaining source sections are outside this pilot.

The common validator reports `valid: true` and `ready`, while its scientific
`certified` fields remain false by design. Project closure means bounded human
acceptance plus the demonstrated technical checks, not universal truth or
independent certification. No raw acquisition was repeated. Every limitation
in the human decision source survives in the claims, specifications, reviews,
delivery and visible report fragment.

Climate portability is the next separate exercise and has not started. Common
schemas, validators, skills and lifecycle rules remain unchanged.
