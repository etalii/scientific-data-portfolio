# Governance and compatibility contract 0.2.0

The complete closed schema is ../schemas/bundle.schema.json. Original artifact
kinds and record payloads remain those of 0.1. The 0.2 record/envelope version is
explicit; historical bundles stay 0.1. Automatic migration/default acceptance is
not provided. Choosing 0.2 requires explicit governance, never silent defaults.

## Fields

- adoption: mode retrospective/in_place/native, nullable cutover_at, history_refs.
- visualization: required/not_required/undecided, rationale, exact spec_refs,
  nullable narrative_ref and decision_ref (null only while undecided), review_refs.
  Decided branches require preserved rationale bytes and a narrative. Delivery
  requires a selected accepted non-automated narrative review referencing those
  exact rationale bytes. Declared visual specs must equal delivered visual specs.
- review_items: unique requirement_id and target/dimension, group_id, target_ref,
  dimension, disposition, nullable review_ref, source_ref, previous_ref, edit_ref.
  Positive dispositions require accepted non-automated passing review of the exact
  target and dimension, citing decision source bytes. ACCEPT WITH EDIT additionally
  requires complete schema-valid earlier same-project/study/artifact/kind revision
  bytes (record or bundle, interpreted under their own 0.1/0.2 record schema), and edit bytes
  cited by that review. Identifier-only predecessors fail. An accepted predecessor
  needs exact passing human review in each dimension required by its version,
  preserved in the snapshot or current records;
  prior content/review external references must resolve with matching hashes.
  Draft/in_review predecessors do not acquire an invented acceptance requirement.
  If supplied, supersedes must agree with the preserved predecessor.
  REJECT/NEEDS INVESTIGATION cannot support accepted targets
  or a delivery. Items preserve groups without cross-product acceptance inference.
- reproducibility: unique dimension entries (input_identity, environment_identity,
  commands, results, rendered_artifacts, clean_clone, cross_platform), each with
  status, scope and evidence_refs. Demonstrated/partial requires evidence. Omitted
  dimension means unassessed, never demonstrated. Dependencies specify name,
  availability and reference. Clean-clone demonstrated conflicts with local_only,
  external or unavailable dependencies. All verified governance files must match.
- registration: nullable except native/post-cutover execution. question_ref,
  plan_ref, contract_refs, input_refs, criteria, registered_at, attestation workspace,
  record_hashes, gate_checks, revision, snapshot_ref and nullable previous_ref.
  The snapshot JSON equals the entire registration except snapshot_ref; compare
  canonical JSON values and verify the referenced file SHA-256. Execution config_refs
  must contain that snapshot's exact path/hash. Freeze exactly question/plan/contracts using
  SHA-256 of the legacy engine's canonical_json(record), including version and
  revision. This is content integrity, not a claim of trustworthy timestamps.
  Revision 1 has no predecessor. Subsequent revisions retain a complete preceding
  registration snapshot with consecutive revision, same logical question and earlier
  registration time. Writers preserve old snapshots/executions and create a new
  execution identity or revision referencing the new snapshot. Validation cannot
  authenticate an author or detect coordinated rewriting of all repository history.

Six gate checks are required exactly once: question_defined, inputs_fixed,
provenance_sufficient, semantics_documented, method_specified,
failure_conditions_defined. Each records passed and rationale. Any false/missing
criterion blocks execution. Record creation must not follow registration;
execution must follow it strictly and use the same plan and exact input hashes.
The validator checks declarations and bytes, not scientific adequacy of a method.

## Review requirements and lifecycle

Every current supported/qualified claim yields a scientific requirement.
Narrative yields narrative/reproducibility requirements; a visual yields
visual/reproducibility requirements. A delivery yields its own scientific
acceptance requirement, which can remain pending for a structurally valid draft
manifest. Accepted targets and presentation/claim prerequisites of any delivery
cannot lack individual positive dispositions. Requirements identify exact
project/artifact/revision/dimension and group where supplied.

0.1 accepted review gates remain in force. 0.2 strengthens them with individual
provenance. A source comment saying “accepted” cannot substitute for a matching
review record. A valid draft may be pending; closure requires accepted delivery
status and the corresponding passing human review. No review is created by the
validator. Review of an original artifact does not authorize a new identity.

Accepted/in-review or positively reviewed narratives are checked without delivery.
All internal refs in the closed narrative payload are assertion claim refs except
those in excluded_claims_with_reasons. Unsupported assertions are rejected at their
exact field path with the offending claim identity. Reviewed narrative assertion
claims require a positive scientific item (whose exact human attestation is checked
separately), cannot be rejected/superseded, and section/general claim sets must agree.
Exclusion references remain valid provenance and are not assertions.

## Shared engine and visual branch

The dual reader loads the unchanged 0.1 implementation privately. 0.2 record
payloads project to the equivalent 0.1 type checks for graph, SHA/path, scope,
scientific review, snapshots and timing. The versioned delivery function retains
those checks and changes only the unconditional visual-spec test: narrative is
always required; visual specification is required unless explicitly not_required.
The separate 0.2 governance checks require purpose, exact branch/spec agreement
and human rationale review. No synthetic visual or broad error suppression occurs.

## Editing and history

Writers must preserve original record/bundle bytes, add new revisions and refresh
current references only. The validator never writes or migrates. Previous_ref
provides exact prior bytes for edited human decisions even when current bundles
select only the new revision. Existing supersedes semantics remain available.
History preservation beyond supplied references is a writer/Git responsibility.
There is no authentication, append-only database, automatic semantic equivalence
or external preregistration service. Existing project ownership/Git policy applies.

## Limits

One project/study per bundle, exact scopes and local contained references remain.
Comparison policies literal/semantic/editorial are documented in spec notes and
review checks; the core cannot automatically judge language equivalence. Human
purpose, authority applicability and scientific claims require human/domain
review. Analysis-ready is not authorization for a stronger downstream question.
