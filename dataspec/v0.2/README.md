# DataSpec 0.2: explicit governance, compatible evidence

Status: approved architecture with three release corrections applied; see verification.md. Historical 0.1 schemas, validator and
pilot records remain unchanged. Read the [architecture delta](architecture_delta.md)
for evidence and classifications before extending the core.

## Run

From the portfolio root (R with jsonlite/digest as in the existing lockfile):

```sh
Rscript dataspec/v0.2/validators/validate.R BUNDLE PROJECT_ROOT
Rscript dataspec/tests/run_tests.R
Rscript dataspec/v0.2/tests/run_tests.R
Rscript dataspec/v0.2/tests/pilot_compatibility.R
```

The new read-only entrypoint accepts 0.1 and 0.2. Historical input uses the original
engine and returns its original report unchanged. 0.2 has a typed `governance`
envelope and 0.2 record versions, retaining the original artifact semantics.
No production dependencies were added. JSON goes to stdout; exit 0 means valid,
1 invalid/blocked, 2 malformed invocation/JSON/runtime error. The validator never
runs analysis, registers decisions, modifies files or approves science.

## Lifecycle and allowed branches

Framing -> planning -> existing data/semantic authorities -> diagnostic criteria
(or justified hypotheses) -> execution -> evidence -> claims -> narrative ->
visualization decision -> implementation/review -> delivery/closure.

- Required visual: claims/narrative -> visual specification -> implementation ->
  scientific/narrative/visual/reproducibility review -> delivery.
- Not required: claims/narrative -> explicit preserved rationale -> narrative and
  reproducibility review plus scientific claim review -> nonvisual delivery.
- Required but missing and undecided cannot deliver. Omission is never exemption.

These are dependency transitions, not an irreversible queue. Changes create new
revisions and invalidate dependent references; existing byte snapshots remain.
The gate for a documentary audit is not authority for a later numerical analysis.
Domain eligibility and engineering rules remain authoritative inside projects.

The router selects a responsibility. The lifecycle skill reads filesystem state,
validator status and user authorization to determine the next action. There is no
database, daemon, remote scheduler, mandatory notebook, Graphene or analysis stack.
R is the repository's validator implementation, not a requirement on study code.

## Adoption modes

- `retrospective`: question/plan remain reconstructed/imported. No prospective
  registration can be asserted for the historical work. Timing gaps stay explicit.
- `in_place`: preserve pre-DataSpec history and a cutover timestamp. Post-cutover
  execution requires the same workspace registration as native work; older work
  retains its original origin. A new bounded study can be native within an older
  scientific repository, as the climate pilot demonstrates.
- `native`: prospective question/plan plus contracts and fixed inputs precede
  execution. The gate can run before execution records exist.

Registration fixes exact question/plan/contract identities AND canonical record
hashes, input file hashes, diagnostic criteria, timestamp and six named gate
checks. A versioned local snapshot contains the whole registration except its
own `snapshot_ref`. Its file SHA-256 binds all these fields, not just the framing
records. Execution `config_refs` must include that exact snapshot path/hash and
use the registered plan and input set after registration. A subsequent registration
increments `revision`, retains `previous_ref`, and requires a new execution
identity/revision bound to the new snapshot. Writers never overwrite snapshots.
It is workspace evidence, not authenticated external preregistration. Updating a
registration and hashes cannot manufacture trustworthy historical evidence; keep
its source/version history immutable under project publication rules.

## Meaning and authority

Evidence is an observed/reproduced result, claim is a proposition supported by
that evidence, and narrative is a communication structure. Insight selection is
an editorial use of claim records, not a duplicate canonical assertion type.
Unsupported candidates may remain explicit with contradicting evidence; they
cannot enter narrative assertions, including nested section references. Only the
explicit `excluded_claims_with_reasons` branch is excluded from assertion traversal.
Accepted/reviewed narratives require consistent section/general claim lists and
scientific dispositions for asserted claims, independently of delivery.

DataSpec references contracts for meaning, invariants, provenance, acquisition,
comparability and recovery. It does not replace them with a generic semantic
ontology. Authority mapping and literal/semantic/editorial comparison policies
use small [templates](templates/authority_map.md), not new domain logic.

## Status axes and review

0.2 reports schema validity, structural/linkage validity, bounded reproduction,
automated attestations, human acceptance, analysis-ready and delivery separately.
The historical field name `structural_validity` means aggregate technical validity,
including governance checks; it is not just schema validity. No field is renamed.
Certification remains `not_assessed`. Valid drafts can await human review.
Accepted claims do not imply universal scientific certification. A new draft
manifest can be valid while awaiting its own acceptance.

Human groups contain individually attributable requirements: exact target,
revision, dimension, disposition, source and human review record. ACCEPT WITH EDIT
also preserves a complete schema-valid earlier record of the same logical object,
including its review provenance when accepted, and review-linked edit evidence.
A draft predecessor is legitimate; acceptance is not invented for it. Old records
are not overwritten. See [the detailed contract](references/governance.md).

Reproduction is a set of scoped demonstrated/partial/not_demonstrated/
not_applicable dimensions with evidence and dependency availability. A local run
cannot imply clean-clone or cross-platform reproduction. The engine detects
contradictions in declared dependencies; it cannot prove that the author listed
all dependencies, really ran a command or evaluated scientific truth.

## Skills

| Skill | Trigger / responsibility | Inputs -> outputs | Status |
|---|---|---|---|
| dataspec-router | Task spans responsibilities | Request + study paths -> applicable skill | New |
| dataspec-lifecycle | Adoption, next step, blocked/pending state | Mode + bundle + findings -> allowed action and prerequisites | New orchestrator |
| dataspec-evidence-review | Assemble evidence or assess claim support | Authorities + observed outputs -> evidence, claims and review needs | New specialist |
| dataspec-story-design | Narrative or visual-purpose decision | Claims + audience -> narrative, explicit branch, optional visual spec | New specialist |
| dataspec-human-review | Human packet or explicit dispositions | Exact targets + evidence + decisions -> review sheet or attributed revisions | New specialist |
| contract-first-data-pipeline | New scientific hand-off authority | Existing contracts + change -> contract-led stage | Retained unchanged |
| scientific-data-comparability-audit | Domain comparison eligibility | Source semantics + scope -> bounded eligibility assessment | Retained unchanged |

The four other existing geographic/rate/render/publication skills retain their
scopes. No common skill embeds either pilot's scientific rules. Descriptions and
SKILL.md live in `.agents/skills`; schema detail and templates live here for
progressive disclosure. New session discovery may be needed for implicit routing.

## Compatibility and examples

The [pilot compatibility test](tests/pilot_compatibility.R) reads both closed
bundles through the dual reader and compares reports byte-for-byte in memory.
It additionally interprets the climate source decisions in a transient 0.2 view,
then validates a draft nonvisual delivery manifest without adding a figure.
The corrected registration snapshot and execution binding exist only in a temporary
copy of the interpretation. They demonstrate v0.2 representation, not a historical
v0.2 registration or approval event.
This proves representation; it does not migrate the closure or fabricate human
acceptance for a newly invented manifest identity. The historical limitation
remains part of the original record, while new 0.2 studies can deliver nonvisually.

[Generate sanitized examples](templates/build_examples.R) produces fictional
visual/nonvisual envelopes from existing synthetic assets. Validate the three
bundle examples with `dataspec` as PROJECT_ROOT. `templates/registration_v1.json`
is the prospective example's frozen snapshot, not a fourth bundle. No example is an
actual scientific result or human review. Start with those and the review and
wording-policy templates; never copy fictional acceptance into a real study.

## Invariants

1. Important claims require evidence.
2. Visuals require analytical purpose.
3. Required visuals cannot silently disappear.
4. No figure is needed merely for lifecycle completion.
5. Final artifacts retain traceability and exact review prerequisites.
6. Technical validity differs from human acceptance.
7. Acceptance differs from universal certification.
8. Reproduction scope is bounded to evidence.
9. Prospective ordering is checked.
10. Retrospective history is not rewritten.
11. Unsupported candidates remain outside narrative assertions.
12. Domain authorities retain their scopes.
13. Specialized contracts are referenced, not duplicated.
14. Durable artifacts, not chat memory, define state.

Some are mechanically enforced (types, links, hashes, review coverage, chronology,
branches); purpose, scientific support, completeness of declarations and truthful
human attestations still require review. Passing tests does not authenticate them.
