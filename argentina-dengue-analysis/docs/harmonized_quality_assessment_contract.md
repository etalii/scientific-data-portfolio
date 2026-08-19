# Harmonized Quality Assessment Contract

## Contract identity

- **Contract ID:** `harmonized_quality_assessment`
- **Version:** `1.0.0`
- **Producer:** `scripts/processing/05_assess_harmonized_quality.R`
- **Input:** `data/processed/canonical_resources_structural.csv`
- **Artifact:** `data/metadata/harmonized_quality_snapshot.csv`

## Purpose and scope

This contract records reproducible, machine-readable quality findings about the
structural-harmonization artifact. It is an assessment, not a cleaning,
canonicalization, deduplication, aggregation, filtering, imputation,
recoding, geography normalization, text repair, or epidemiological-analysis
stage. It does not modify its input, raw data, or any observation value.

A **quality finding** is an observed property published in the snapshot. It is
not an execution failure. An **execution error** is a condition that prevents a
reliable assessment and aborts before publication.

## Inputs and preconditions

All paths are read only from `config/project.yml`:

- `directories.processed_data`;
- `directories.metadata`;
- `artifacts.canonical_resources_structural`;
- `artifacts.harmonized_quality_snapshot`.

The input must satisfy `structural_harmonization` v1.0.0: its exact ordered
schema is the 14-column schema of that contract; CSV syntax must be valid; the
logical key `(source_resource_id, source_row_number)` must be unique; source
row numbers must be positive integers; `source_year` must be 1000--9999;
`source_week` must be 1--53; and `source_case_count` must be a non-negative
integer. The producer reports current row, resource, and family counts for
regression review but does not hard-code them as universal input requirements.

The current input is expected to contain 39,547 rows, four resources, and two
source-schema families. Those are regression expectations only.

## Snapshot schema

Rows are one affected source observation per diagnostic group, except
`no_published_rows_for_week`, which represents the absence of a source
observation.

| Column | Type | Nullable | Description |
| --- | --- | --- | --- |
| `quality_schema_version` | string | No | Always `1.0.0`. |
| `diagnostic_group_id` | lowercase SHA-256 hexadecimal string | No | Stable identifier for one finding group. |
| `diagnostic_type` | controlled string | No | Kind of finding. |
| `diagnostic_domain` | controlled string | No | Affected quality domain. |
| `severity` | controlled string | No | Consequence for future policy-controlled work. |
| `source_resource_id` | string | Yes | Source resource of an affected observation. Null when no observation exists. |
| `source_row_number` | positive integer | Yes | Source-row provenance of an affected observation. Null when no observation exists. |
| `source_schema_family` | string | Yes | Family of the affected observation, or contextual family for an absence finding. |
| `source_year` | integer | Yes | Source year of the observation, or contextual year for an absence finding. |
| `source_week` | integer | Yes | Source week of the observation, or contextual missing week. |
| `field_name` | string | Yes | Contractual field or field set assessed. |
| `group_size` | non-negative integer | No | Number of observed rows in the diagnostic group; zero for an absence finding. |
| `context_resource_id` | string | Yes | Resource context for a finding with no source observation; null otherwise. |

`source_resource_id + source_row_number` joins every observation-level finding
back to the structural artifact. For `no_published_rows_for_week`, both are
null and `context_resource_id`, `source_schema_family`, `source_year`, and
`source_week` identify the assessed published-resource position.

The snapshot has no run identifier, timestamps, serialized row lists, or
free-form narrative fields.

## Controlled vocabularies

### Diagnostic type

- `exact_content_duplicate`
- `same_candidate_dimensions_same_count`
- `same_candidate_dimensions_count_conflict`
- `province_id_name_conflict`
- `department_id_name_conflict`
- `unknown_geography`
- `age_group_id_label_conflict`
- `unspecified_age_group`
- `text_source_anomaly`
- `no_published_rows_for_week`
- `event_dimension_overlap`

### Diagnostic domain

- `row_identity`
- `geography`
- `age_group`
- `temporal_coverage`
- `text`
- `event_semantics`

### Severity

- `info`: descriptive evidence that does not itself require a corrective
  policy.
- `warning`: a source property that future users should consider explicitly.
- `blocking`: a future transformation relying on this property must not resolve
  the finding automatically without an approved policy.

`blocking` never means that this producer aborts or that the whole dataset has
one global validity state.

## Diagnostic definitions

### Row identity

`exact_content_duplicate` groups records equal in every structural field except
`source_resource_id`, `source_local_filename`, and `source_row_number`.

`same_candidate_dimensions_same_count` groups records equal in
`source_schema_family`, `province_id`, `department_id`, `source_year`,
`source_week`, `event`, `source_age_group_id`, and `source_case_count`. It
intentionally excludes descriptive names and age labels, so it can include
groups that are not exact-content duplicates.

`same_candidate_dimensions_count_conflict` groups records equal in the same
candidate dimensions excluding `source_case_count`, but with more than one
distinct `source_case_count`.

All three are `blocking` in domain `row_identity`. They are evidence for a
future consolidation policy, not instructions to deduplicate.

### Geography

`province_id_name_conflict` occurs when one `province_id` maps to multiple
distinct `province_name` values within a `source_schema_family`.

`department_id_name_conflict` occurs when one
`(source_schema_family, province_id, department_id)` maps to multiple distinct
`department_name` values. No case, spelling, padding, or accent correction is
performed.

Both conflicts are `blocking` in domain `geography`. `unknown_geography` is a
`warning` in that domain and occurs only when `province_name` or
`department_name`, after ASCII case folding, equals `desconocida` or
`desconocido`. Values are preserved; IDs are not converted to missing values.

### Age groups and text

`age_group_id_label_conflict` occurs when one
`(source_resource_id, source_schema_family, source_age_group_id)` has multiple
distinct `source_age_group_label` values. It is `blocking` in domain
`age_group`. Different vocabularies across families are not findings by
themselves.

`unspecified_age_group` is a `warning` in domain `age_group` when an exact
source label, after ASCII case folding, equals `sin especificar`. The source
label and ID remain unchanged.

`text_source_anomaly` is a `warning` in domain `text` when
`source_age_group_label` contains the explicitly observed literal `dÍas`.
It records preserved source text only; it neither detects arbitrary unusual
text nor repairs mojibake.

### Temporal coverage

`no_published_rows_for_week` is an `info` finding in domain
`temporal_coverage` for each unobserved week in the contractual range 1--53
for each `(source_resource_id, source_year)`. It means only that the artifact
has no published record for that resource/year/week. It does not establish
zero cases, source missingness, or provider error. It has `group_size = 0` and
no row-level provenance.

### Event semantics

`event_dimension_overlap` is `blocking` in domain `event_semantics` when the
same full descriptive dimensions (schema family; province and department IDs
and names; source year and week; source age-group ID and label) occur for both
`Dengue` and `Dengue durante la gestación`. It is descriptive evidence only:
it does not claim duplication, subset membership, or an epidemiological
relationship, and does not filter either event.

## Deterministic group identity and ordering

For every group, the producer creates a canonical finding key from
`diagnostic_type` and the relevant grouping fields. Each field is serialized in
fixed field-name order as `name:byte_length:value`, UTF-8 encoded; null is
represented by the fixed token `NA`. `diagnostic_group_id` is the lowercase
SHA-256 hexadecimal digest of that serialization. It therefore contains no
run state and is independent of input order.

The snapshot is ordered ascending by `diagnostic_type`, `diagnostic_group_id`,
then `source_resource_id` and `source_row_number`, with null values sorted
before non-null values at each nullable key. This order, a fixed schema, and
CSV serialization make unchanged inputs byte-for-byte reproducible.

## Publication and version control

The producer constructs and validates the complete snapshot before writing. It
writes a project-owned temporary CSV in the configured metadata directory and
atomically renames it over the configured artifact. A failure preserves any
previous snapshot and cleans only its controlled temporary file.

The snapshot is regenerable operational metadata and is ignored by Git. This
contract, the script, and its configuration are versioned.

## Execution errors

The producer aborts before publication only when configuration is invalid;
paths leave their configured areas; the input is absent, unreadable, malformed,
or schema-incompatible; contractual types or structural invariants are
invalid; or atomic publication fails. Quality findings never cause an abort.
