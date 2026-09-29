# Verification: DataSpec 0.2 release corrections

Date: 2026-09-29. HEAD: 4e9330e26cf72f0345fa10905aa74710660797e5.
Status: READY FOR RELEASE COMMIT. No staging, commit or push in this unit.

## Human dispositions

The requesting user explicitly approved R1 lifecycle/narrative/delivery, R2
review/validity and R3 reproduction/provenance with the three specified edits.
R4 skill architecture and R5 compatibility/versioning were accepted unchanged.
The exact instruction is preserved in [release_dispositions.txt](references/release_dispositions.txt),
SHA-256 `825634bf8528b4267c86e4a61e56b2f94a3cfd95545315cc689452e30ea98500`.
These are release architecture decisions, not new scientific pilot approvals.

## Corrections and contract mechanisms

1. Narrative validation walks every internal assertion reference in the closed
   narrative payload, including sections. Only the explicit exclusion branch is
   omitted from assertion checks. Unsupported references identify both narrative
   and offending claim in deterministic findings. Reviewed/accepted narratives
   require consistent section/general claim sets and positive scientific claim
   dispositions independently of delivery. Exact human attestations remain checked.
2. ACCEPT WITH EDIT requires one complete predecessor matching its own explicit
   0.1/0.2 record schema, project/study/artifact/kind and an earlier revision.
   Identifier-only objects fail. Prior content and review source hashes resolve;
   accepted predecessors require preserved exact passing human review in every
   dimension required by their version. Legitimate
   draft predecessors remain allowed. An explicit supersedes must agree. This is
   preserved content and attributed review, not reviewer authentication.
3. Registration adds revision, snapshot_ref and nullable previous_ref. The local
   snapshot equals the full registration except its own snapshot_ref. The validator
   checks canonical content equality and the file SHA-256. Execution config_refs
   must include that exact snapshot identity. Criteria, gates, inputs, framing
   hashes and timestamp are all covered. Revised registration preserves its complete
   predecessor with consecutive revision and earlier time; new execution binds the
   new snapshot and still follows registration. Writers preserve execution/history
   revisions. Coordinated rewriting of all history is not externally detectable;
   no signature or trusted timestamp is claimed.

The only new registration machinery is a local JSON snapshot, existing external
references/config_refs and registration revision metadata. No execution payload
extension, service, dependency, scientific rule or automatic migration was added.
`structural_validity` is documented as aggregate technical validity, without rename.

## Results

| Check | Result |
|---|---|
| Historical suite | 48/48 PASS, unchanged |
| Previous v0.2 scenarios | 58/58 PASS |
| New semantic scenarios | 20/20 PASS |
| Current v0.2 suite | 78/78 PASS |
| Total regression scenarios | 126/126 PASS |
| Dengue historical bundle | 20 records, zero findings, identical old/new reports |
| Climate historical bundle | 20 records, zero findings, identical old/new reports |
| Climate transient governed interpretation | PASS with new snapshot only in temporary copy |
| Climate nonvisual draft delivery | PASS, no fake visual or new historical acceptance |
| Schema regeneration | Byte-identical |
| Three example bundles and registration snapshot regeneration | Byte-identical |
| Three example validations | Valid; repeated reports identical |
| Five skill formats and nine relative links | PASS |
| git diff --check | PASS |

## Added semantic regressions

Every scenario below passes; negative cases require the stated rejection rather
than simply accepting any exception. Existing expectations were not relaxed.

| # | Scenario | Expected result |
|---|---|---|
| 1 | Accepted narrative has unsupported section claim without delivery | CLAIM, exact narrative/claim and deterministic findings |
| 2 | Accepted narrative explicitly excludes unsupported candidate | Valid |
| 3 | Reviewed allowed claims at top and section levels | Valid |
| 4 | Accepted narrative general/section claim sets differ | CLAIM |
| 5 | Accepted narrative assertion lacks scientific disposition | REVIEW |
| 6 | Edited object preserves complete accepted predecessor and review | Valid |
| 7 | Predecessor contains only identifiers | REVIEW |
| 8 | Complete predecessor has wrong logical identity | REVIEW |
| 9 | Complete predecessor revision is not earlier | REVIEW |
| 10 | Complete historical 0.1 draft predecessor, no invented approval | Valid |
| 11 | Accepted predecessor lacks exact historical human review | REVIEW |
| 12 | Analytical expectation changes while snapshot/execution stay fixed | HASH |
| 13 | Gate rationale changes while snapshot/execution stay fixed | HASH |
| 14 | Execution omits registration snapshot identity | GATE |
| 15 | New registration and execution revisions preserve history/order | Valid |
| 16 | New registration paired with old execution snapshot reference | GATE |
| 17 | New execution begins before its new registration | TIMING |
| 18 | New registration omits preceding snapshot | GATE |
| 19 | Accepted predecessor specification retains both review dimensions | Valid |
| 20 | Accepted predecessor specification lacks reproduction review | REVIEW |

## Pilot compatibility and preservation

Both original 0.1 bundles dispatch directly to the unchanged historical engine.
Dengue keeps accepted edited lineage, retrospective provenance, visual delivery
and all original outputs. Climate keeps 51 pinned inputs, original chronology,
qualified claims, unsupported/excluded claim_direct_suitability and human closure.
No project file or scientific conclusion was edited.

The climate compatibility script copies referenced local artifacts to a disposable
root, derives the v0.2 snapshot there, and binds only the transient execution view.
That new binding is explicitly not a historical v0.2 registration event. Its new
nonvisual delivery remains draft; historical approval is not extended to it.
Source bundles and historical reports remain byte-identical. No raw processing,
new raster sampling, render or data acquisition occurs.

Preservation audit compares all 401 initially tracked/untracked file identities.
Only intended common v0.2 authoring files changed during this correction unit.
Both projects, ten original loose climate files, v0.1 and all eleven skills retain
identical bytes. No staged changes. Ignored analytical inputs are read-only inputs
to validation, not regeneration targets.

## Fourteen invariants

| # | Invariant | Assessment and mechanism |
|---|---|---|
| 1 | Claims require evidence | SATISFIED: retained claim/evidence rules; substantive support still human |
| 2 | Visual analytical purpose | SATISFIED: explicit rationale/spec and human review |
| 3 | Required visual cannot disappear | SATISFIED: required branch and exact delivered specs |
| 4 | No decorative lifecycle figure | SATISFIED: reviewed nonvisual branch can close |
| 5 | Final traceability and exact review | SATISFIED: existing dependency closure plus schema-valid predecessor content, identity, source hashes and accepted prior review provenance |
| 6 | Validity differs from acceptance | SATISFIED: valid drafts may remain pending |
| 7 | Acceptance differs from certification | SATISFIED: scientific certification remains not_assessed |
| 8 | Bounded reproduction | SATISFIED: dimensions, evidence and declared dependencies |
| 9 | Prospective ordering | SATISFIED: whole-registration snapshot/hash consumed by execution, predecessor revision/time and existing before-execution checks; local integrity only |
| 10 | Retrospective history retained | SATISFIED: origin constraints, unchanged pilots, writer preservation obligations |
| 11 | Unsupported candidates outside assertions | SATISFIED: traversal of every schema-supported narrative assertion reference, separate exclusions, no delivery dependency |
| 12 | Domain authorities retain scope | SATISFIED: no project scientific rules in core |
| 13 | Specialized contracts referenced | SATISFIED: existing contract-first skill and authority map |
| 14 | Durable artifacts define state | SATISFIED: read-only validator and filesystem-based skills |

Human purpose, scientific adequacy, truthful attribution and completeness of
external declarations remain human responsibilities, not validator guarantees.

## Focused self-review

1. No schema-supported narrative assertion claim-ref path bypasses unsupported
   checking. Exclusion refs are intentionally provenance, not assertions.
2. Identifier-only or schema-invalid predecessors cannot support edited acceptance;
   accepted prior objects require preserved review provenance.
3. Criteria cannot change while retaining a valid unchanged execution snapshot
   identity. Reauthoring all history remains outside local integrity guarantees.
4. No fix adds project-specific logic to the core or common skills.
5. No fix changes 0.1 schema, runtime, CLI or dispatch semantics.
6. No fix changes historical project files or approvals.
7. Existing reference/config machinery suffices; no services or duplicate workflow.

## Commit scope and deferrals

The exact allowlist is [commit_scope.txt](commit_scope.txt): one modified common
file and 28 new common files. Relative to the prior implementation, the two added
files are the synthetic registration snapshot and the exact human release request.
Both scientific projects and all ten pre-existing loose climate files are excluded.
No temporary fixtures, raw data, processed indicators or environment artifacts belong
in the release. No staging, commit or push was performed.

Reviewer authentication, external timestamping, automatic semantic equivalence,
automatic dependency-completeness proof, migration, services/databases and mandatory
Graphene integration remain deferred. Skill assessment remains static/manual,
not a claim of independent agent-discovery evaluation.
