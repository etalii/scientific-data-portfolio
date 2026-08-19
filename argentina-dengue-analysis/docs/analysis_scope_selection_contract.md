# Analysis Scope Selection Contract

## Contract identity

- **Contract ID:** `analysis_scope_selection`
- **Version:** `1.0.0`
- **Producer:** `scripts/processing/06_select_analysis_scope.R`
- **Artifact:** `data/processed/primary_dengue_analysis_rows.csv`

## Purpose and scope

This contract creates an explicit, deterministic analytical subset of the
structural-harmonization artifact. It represents the primary portfolio scope:
published records whose configured source year and event satisfy the primary
scope criteria.

The current methodological interpretation is that aggregates of selected
`source_case_count` values are sums of published records, not reconstructions
of unique individual cases.

This is a selection stage, not cleaning. It does not deduplicate, consolidate,
aggregate, correct text or geography, recode age groups, impute, complete
weeks, alter `source_case_count`, or resolve quality findings.

## Material inputs

The producer reads only centrally configured paths and criteria from
`config/project.yml`:

- `directories.processed_data`;
- `artifacts.canonical_resources_structural`;
- `artifacts.primary_dengue_analysis_rows`;
- `analysis_scope.primary.scope_id`;
- `analysis_scope.primary.source_years`;
- `analysis_scope.primary.events`.

Its sole material data input is `structural_harmonization` v1.0.0. The
harmonized-quality snapshot is deliberately not an input: none of its findings
changes C.8 selection criteria in this version. It remains the independent
source of quality evidence for future analytical choices.

## Selection rule

A source row is selected if and only if:

1. `source_year` belongs to `analysis_scope.primary.source_years`; and
2. `event` belongs to `analysis_scope.primary.events`.

For the configured primary scope v1.0.0, this is `source_year == 2024` and
`event == "Dengue"`. The resource ID is not a criterion. After selection,
exactly one `source_resource_id` must be present. A multiple-resource result
aborts before publication because it changes the intended methodological
composition and requires an explicit scope or contract revision.

Events not configured for the primary scope, including `Dengue durante la
gestación` and `Enfermedad por Virus del Zika`, are excluded solely because
they do not meet the configured rule. Their exclusion does not claim a
clinical or epidemiological relationship between events.

## Input validation

The source artifact must have exactly the ordered 14-column
`structural_harmonization` v1.0.0 schema. Its CSV must be syntactically valid;
the logical key `(source_resource_id, source_row_number)` must be unique;
`source_row_number` must be positive; `source_year` must be 1000--9999;
`source_week` must be 1--53; `source_case_count` must be a non-negative
integer; each resource must have one filename and one source-schema family;
and row numbers must be sequential within a resource.

The configured scope ID must be a non-empty string. `source_years` must be a
non-empty integer vector in 1000--9999 and `events` a non-empty vector of
non-empty strings. Paths must be project-relative and the input and output
must belong to the configured processed-data directory.

## Output schema

Rows are sorted by `source_resource_id`, then `source_row_number`. The 14
structural fields retain their exact source-contract semantics and order after
the two scope fields.

| Column | Type | Nullable | Description |
| --- | --- | --- | --- |
| `analysis_scope_schema_version` | string | No | Always `1.0.0`. |
| `analysis_scope_id` | string | No | Configured stable methodological scope identifier. |
| `source_resource_id` | string | No | Unchanged structural source resource ID. |
| `source_local_filename` | string | No | Unchanged structural source filename. |
| `source_row_number` | positive integer | No | Unchanged source-record ordinal. |
| `source_schema_family` | string | No | Unchanged structural source family. |
| `province_id` | string | Yes | Unchanged decoded source value. |
| `province_name` | string | Yes | Unchanged decoded source value. |
| `department_id` | string | Yes | Unchanged decoded source value. |
| `department_name` | string | Yes | Unchanged decoded source value. |
| `source_year` | integer | No | Unchanged source year position. |
| `source_week` | integer | No | Unchanged source week position. |
| `event` | string | Yes | Unchanged source event value. |
| `source_age_group_id` | string | Yes | Unchanged source age-group code. |
| `source_age_group_label` | string | Yes | Unchanged source age-group label. |
| `source_case_count` | non-negative integer | No | Unchanged published count. |

## Preservation invariants

- Every and only source rows satisfying the configured scope rule appear once.
- No selected row is removed or duplicated.
- Every selected structural field is value-equivalent to its matching input
  row, including `source_case_count`.
- `(source_resource_id, source_row_number)` remains unique and joins exactly
  to the structural source artifact.
- No selected row has a year or event outside the configured scope.
- Exactly one source resource composes the v1.0.0 primary scope.
- Exact duplicates, candidate-dimension count conflicts, unknown geography,
  unspecified age, and source text anomalies are preserved if selected.
- No source rows are created for weeks with no published records; absence of a
  row never means zero cases.
- The structural input and all upstream artifacts remain unchanged.

## Publication and version control

The producer constructs and validates the complete output before writing. It
writes a project-owned temporary CSV in the configured processed-data directory
and atomically renames it into place. Failure preserves a previous valid output
and cleans only the producer's temporary file.

The output is regenerable processed data and is ignored by Git. The script,
configuration, and this contract are versioned.

## Blocking errors

Execution aborts before publication for invalid configuration or paths; absent,
unreadable, malformed, or schema-incompatible input; invalid source-contract
types or invariants; an empty selected scope; a selected scope spanning more
than one resource; failed preservation invariants; or failed atomic
publication. Quality findings are not execution errors and are not read to
change selection.
