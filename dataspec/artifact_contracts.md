# Minimum artifact contracts

## Contract status

Family: `dataspec_artifacts`, version `0.1.0`. These logical contracts are
implemented by the [bundle schema](schemas/bundle.schema.json) and read-only
validator. The [executable validation contract](validation_contract.md) refines
nested types, minimum scope, and conditional checks. No record writer is supplied.
Unspecified scientific parameters belong to project contracts.

## Common record envelope

All records use these fields. Strings are nonempty UTF-8; timestamps use RFC
3339 UTC; revisions are positive integers. No implicit type coercion or unknown
fields are allowed, except a namespaced `extensions` object. Null is forbidden
unless explicitly allowed below; optional fields are omitted when inapplicable.

| Field | Type / rule |
| --- | --- |
| `schema_version` | String, exactly `0.1.0` for this proposed family |
| `project_id` | Stable snake_case string; `dataspec` reserved for framework changes |
| `study_id` | Stable snake_case string; nullable for framework-level changes only |
| `artifact_id` | Stable snake_case string unique within a project |
| `revision` | Positive integer; identity is project + artifact + revision |
| `kind` | One of the kinds in the table below |
| `owner` | String naming the responsible role or person |
| `created_at` | Timestamp for this record, never a backdated analysis date |
| `record_origin` | `prospective`, `retrospective`, or `imported` |
| `status` | `draft`, `in_review`, `accepted`, `rejected`, or `superseded` |
| `depends_on` | Array of exact internal references, possibly empty |
| `supersedes` | Optional exact reference to an earlier revision |
| `limitations` | Array of strings, possibly empty with reviewed justification in payload |
| `payload` | Object specific to `kind` |
| `extensions` | Optional object; keys must include an owning namespace |

An internal reference contains exactly `project_id`, `artifact_id`, and
`revision`. Floating references such as `latest` are invalid. Cross-project
references must be declared by the project adapter, never inferred by name.

An external artifact reference contains `path`, `sha256`, `locator`, and
`availability`. Paths are project-relative POSIX paths without traversal; SHA-256
is 64 lowercase hexadecimal characters. A locator is a nonempty section, row
key, figure identifier, or equivalent precise selector. Availability is
`verified_local` or `unavailable`; only the latter permits null hash/locator,
with a required `reason`. An unavailable reference cannot support acceptance
of a computational claim. A URL alone is discovery context, not verified bytes.

Arrays representing sets have unique entries sorted by their identity fields;
arrays representing narrative order, chart order, or commands preserve sequence.
Object key order has no semantic meaning. File hashes identify exact bytes;
no canonical-content hash is implied. An executable serialization contract must
be fixed before any writer computes content-derived identities.

## Kinds and minimum payloads

Every listed field is required unless marked optional. Prose fields are strings;
references use the structures above; plural references and lists are arrays.
Typed nested structures and implementation-specific refinements are defined in
the executable schema and validation contract.

| Kind | Owner and minimum payload | Consumers |
| --- | --- | --- |
| `question` | Study owner: `question_text`, `intended_use`, `audience`, `scope`, `non_goals`, `answer_criteria` | Plan, review |
| `analysis_plan` | Analyst: `question_ref`, `design_type`, `methods`, `contract_refs`, `metric_refs`, `hypothesis_refs`, `validation_strategy`, `sensitivity_policy`, `stopping_rule` | Implementer, scientific reviewer |
| `data_contract_ref` | Project contract owner: `contract_id`, `contract_version`, `document_ref`, `producer_ref`, `consumer_roles` | Plan, metrics, execution |
| `metric` | Semantic owner: `contract_ref`, `definition_locator`, `grain`, `unit`, `dimensions`, `population_or_domain`, `time_basis`, `spatial_basis`, `missingness_policy`, `aggregation_policy`, `join_policy`, `computation_ref`, `interpretation_limits` | Evidence, claims, charts |
| `hypothesis` | Analyst: `question_ref`, `statement`, `hypothesis_type`, `formulated_at`, `timing_evidence_refs`, `evaluation_rule` | Plan, evidence review |
| `execution` | Analytical producer: `plan_ref`, `command`, `working_directory`, `code_refs`, `config_refs`, `environment_ref`, `input_refs`, `output_refs`, `started_at`, `finished_at`, `exit_code`, `validation_refs`, `reproduction_status` | Evidence, reproducibility review |
| `evidence` | Evidence producer: `evidence_type`, `source_refs`, `execution_refs`, `result_locator`, `scope`, `finding`, `uncertainty`, `validation_refs` | Claims, scientific review |
| `claim` | Analyst/editor: `question_ref`, `claim_text`, `claim_type`, `supporting_evidence_refs`, `contradicting_evidence_refs`, `metric_refs`, `scope`, `caveats`, `disposition` | Narrative, visual, review |
| `narrative_spec` | Editor: `audience`, `communication_goal`, `ordered_sections`, `claim_refs`, `context_source_refs`, `mandatory_caveats`, `excluded_claims_with_reasons` | Presentation implementer, reviewer |
| `visualization_spec` | Visualization designer: `claim_refs`, `metric_refs`, `input_refs`, `chart_type`, `encodings`, `transformations`, `labels`, `uncertainty_display`, `accessibility_criteria`, `render_targets`, `qa_criteria` | Chart implementer, visual reviewer |
| `review` | Named reviewer: `target_refs`, `reviewer`, `review_mode`, `review_dimensions`, `checks`, `findings`, `disposition`, `reviewed_at` | Acceptance, delivery |
| `delivery` | Release owner: `question_ref`, `deliverable_refs`, `claim_location_map`, `review_refs`, `dependency_snapshot`, `reproduction_instructions`, `known_gaps`, `delivery_disposition` | Reader, future reproduction |
| `change` | Change owner: `reason`, `target_refs`, `impact`, `tasks`, `required_checks`, `closure_refs` | Coordinator, maintainers |

`scope` and metric policies must use a structured project-defined representation
whose schema is referenced by the adapter. Where a metric has no spatial basis
or denominator, record explicit non-applicability and a reason; do not invent it.
Existing contracts remain the authority for scientific formulas and thresholds.

## Conditional requirements

- `design_type`: `descriptive`, `exploratory`, `confirmatory`, or `predictive`.
  A plan with empty `hypothesis_refs` requires `hypothesis_omission_reason`.
- `hypothesis_type`: `exploratory` or `confirmatory`. `formulated_at` may be
  null only with `timing_unknown_reason`. Confirmatory status requires dated
  evidence of pre-specification before the relevant result was examined.
  Retrospective registration alone never establishes that timing.
- `evidence_type`: `computational`, `documentary`, or `methodological`.
  Computational evidence requires at least one execution with verified output
  references. Documentary evidence requires a preserved source and precise
  locator; it may have no analytical execution. Methodological evidence records
  its supporting sources and an explicit assessment, without inventing a run.
- `claim_type`: `descriptive`, `associational`, `predictive`, `causal`, or
  `methodological`. Claim `disposition`: `supported`, `qualified`,
  `unsupported`, or `inconclusive`. Causal claims require explicit project
  authorization and supporting design. Empty supporting evidence cannot yield
  `supported` or `qualified`; contradicting evidence must remain visible.
- `reproduction_status`: `not_attempted`, `passed`, `failed`, or `blocked`.
  A successful exit code alone does not imply `passed`. Missing historical run
  details must be recorded as gaps; never invent timestamps or execution logs.
- `review_mode`: `self`, `independent`, or `automated`.
  `review_dimensions` draws from `scientific`, `narrative`, `visual`, and
  `reproducibility`. Review `disposition`: `pass`, `revise`, or `block`.
  Exact target revisions and findings are mandatory. Self-review is permitted
  where project policy permits it, but cannot be labeled independent.
- `delivery_disposition`: `answer`, `qualified_answer`, or `inconclusive`.
  An inconclusive delivery must explain why the question cannot be resolved.
  It cannot present an unsupported substantive claim as an answer.

Narrative sections and rendered claim locations must reference claim IDs;
external factual context must reference preserved sources. Labels, navigation,
and other nonfactual connective text do not need artificial evidence records.
Charts may apply declared display transformations only. New analytical
aggregation or inference returns to the analysis plan and evidence stage.

## State and validation semantics

Authoring status is distinct from observed readiness and execution history.
The validator reports `ready`, `blocked`, or `stale` against an explicit
candidate dependency snapshot. It also reports separately whether a stage is
specified, implemented, executed, and certified, with evidence for each property.
These properties are not inferred from one another. The minimum validator
reports recorded evidence and always leaves scientific certification unassessed.

Normal authoring transitions are `draft -> in_review -> accepted` or `rejected`.
Revision requests return unaccepted work to draft. Accepted records are frozen;
supersession is recorded by a new revision/change without editing the accepted
bytes. Superseded status is derived for historical accepted records from that
relationship. Review records target exact revisions, and acceptance is supported
by a separate review record, avoiding mutual dependency cycles.

Acceptance checks must reject duplicate identities, dangling references,
dependency cycles, hash mismatches, undeclared schema versions, incompatible
scopes, unsupported claims presented as answers, and missing required reviews.
Scope compatibility that cannot be decided generically requires a project
check or methodological review; the generic validator must report it unresolved.
Review validity is scoped to target revisions: a new input or specification
invalidates dependent acceptance for a new delivery until review is repeated.

## Writer and Git policy

One owning producer writes each record; validators are read-only. Failures
publish no accepted artifact. Writers validate the complete candidate bundle,
then publish atomically on the destination filesystem. Existing identity with
different bytes is an error, never an overwrite permission.

Human-authored plans/specifications belong in Git. Generated provenance records
require project-specific designation before tracking. DataSpec must not copy
generated analysis tables into a versioned evidence register. References and
reproduction instructions preserve linkage without changing raw-data or
generated-file policies.
