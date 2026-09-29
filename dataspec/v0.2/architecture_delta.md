# Architecture decision before implementation: DataSpec 0.2

Evidence: dengue rank_shift_2024/framework_feedback.md and closure.md; climate
bio01_pair_eligibility/stabilization_input.md and closure.md. Both accepted bundles
remain historical 0.1. No scientific project file or original record is migrated.

| Core concern | Dengue evidence | Climate evidence | Current 0.1 behavior | Required 0.2 decision / classification |
|---|---|---|---|---|
| Actionable human review | Generic requirements needed exact targets | Six groups reduced to D1-D3 | Review links exist, no requirement sheet | Emit exact revision/dimension requirements; CONFIRMED CROSS-PROJECT |
| Group dispositions | ACCEPT WITH EDIT and individual requirements | Three explicit decisions cover five claims/narrative | Project sidecars retain dispositions | Typed per-item group/source/edit provenance; CONFIRMED CROSS-PROJECT |
| Reproduction | Selected calculations and figure, not whole report | Metadata/local inputs, not clean clone | Single execution reproduction_status plus prose | Scope dimensions with evidence and dependencies; CONFIRMED CROSS-PROJECT |
| Validity/acceptance | Human decisions separate from machine checks | Valid drafts precede human closure | Existing states partly separate | Derived status axes and next action; CONFIRMED CROSS-PROJECT |
| History | Original revisions/config replay | Original 18-record bundle, seven initial records unchanged | Exact revision graph already available | Retain references, require edit predecessor provenance; CONFIRMED CROSS-PROJECT |
| Nonvisual delivery | Visual required and present | No useful visual; closure without delivery | Both specs mandatory | Explicit reviewed not_required branch; LIKELY GENERAL FROM ONE PILOT |
| Registration | Reconstructed provenance | 51 inputs before execution | Project-local gate | Optional workspace registration; native requires gate; LIKELY GENERAL FROM ONE PILOT |
| Cutover | Retrospective import | Active project, new prospective unit | Origins per record only | Three adoption modes, same record model; LIKELY GENERAL FROM ONE PILOT |
| Literal vs semantic | Captions differ literally | Family linkage is a different domain question | Prose in checks | Template for field comparison policy, no ontology/schema extension; LIKELY GENERAL FROM ONE PILOT |
| Domain suitability | Rates/geography | Encoding and climate authority | Project adapters | No common thresholds; PROJECT-SPECIFIC |
| Automatic truth certification | Neither demonstrates it | Neither demonstrates it | not_assessed | Retain not_assessed; INSUFFICIENT EVIDENCE |

## Minimal implementation boundary

Keep 0.1 schema/core/CLI unchanged. Add a versioned 0.2 envelope and dual-version
read-only entrypoint. Existing typed record semantics remain unchanged, versioned
0.2 in the new envelope. A private 0.1 projection reuses graph/hash/scope/review
checks; a narrowly overridden delivery rule replaces only the mandatory visual
rule, retaining every other delivery check. No fabricated visual record and no
post-hoc removal of unrelated validation errors.

Additional envelope governance: adoption, visualization decision, review items,
bounded reproducibility, optional registration. Every reference is validated.
Core is a filesystem protocol; orchestration returns advice, never executes code
or grants scientific approval. Publication, services, remote timestamping and
Graphene integration remain out of scope.

## Skills decision

Authority mapping: KEEP AS REFERENCE/TEMPLATE; retain contract-first skill.
Evidence assembly + claim support: CREATE SKILL (one evidence-review behavior).
Narrative + visual purpose/spec: CREATE SKILL (one story-design behavior).
Human packet/dispositions: CREATE SKILL.
Lifecycle coordination: KEEP IN ORCHESTRATOR (new narrow skill).
Routing: one new router skill. No skill per record. Central references in this
version directory; five short repository-discoverable skills, no domain rules.

## Accepted release corrections (2026-09-29)

The human accepted R1-R3 with edits and R4-R5 unchanged; exact source and results
are recorded in verification.md. The three bounded corrections are narrative
assertion traversal before delivery, complete predecessor/review preservation,
and a complete local registration snapshot consumed by execution config_refs.
These strengthen the accepted abstractions without changing the original 0.1
runtime or pilot history. The transient climate binding is derived in a disposable
copy; it is not asserted to be a historical registration or approval.
