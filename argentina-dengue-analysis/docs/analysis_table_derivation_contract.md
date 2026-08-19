# Analysis Table Derivation Contract

## Contract identity

- **Contract ID:** `analysis_table_derivation`
- **Version:** `1.0.0`
- **Producer:** `scripts/analysis/07_build_analysis_tables.R`
- **Input:** `data/processed/primary_dengue_analysis_rows.csv`

## Purpose and scope

This contract derives deterministic analytical tables from the selected primary
scope. Every aggregate represents a sum of **published rows** and **published
counts**. It does not represent unique people, deduplicated individual cases,
incidence, prevalence, or risk.

The producer does not deduplicate, consolidate, correct, recode, impute,
filter, complete missing weeks, or otherwise resolve findings preserved by C.7
and C.8. It aggregates every input row in the relevant contractual group.

## Material input

The sole material data input is `analysis_scope_selection` v1.0.0 at the
configured `artifacts.primary_dengue_analysis_rows` path. The producer also
reads only the configured processed-data directory and four output paths from
`config/project.yml`.

`harmonized_quality_snapshot.csv` is not a dependency. Its findings remain
methodological evidence but do not change C.9 aggregation rules.

The input must have the exact ordered 16-column C.8 schema, one
`analysis_scope_schema_version` equal to `1.0.0`, one non-empty
`analysis_scope_id`, one `source_resource_id`, and one `source_year`. Its
`event` must likewise contain one non-empty selected value. Its
source provenance key must be unique; source row numbers must be positive;
weeks must be 1--53; source counts must be non-negative integers; and all
input rows must have non-empty scope and resource provenance.

## Common fields and semantics

All output artifacts begin with:

| Column | Type | Description |
| --- | --- | --- |
| `analysis_table_schema_version` | string | Always `1.0.0`. |
| `analysis_scope_id` | string | C.8 scope identifier. |
| `source_resource_id` | string | Canonical resource from which the aggregate derives. |
| `source_year` | integer | Sole source-year position of the input scope. |

`published_row_count` is the number of C.8 rows in an aggregate. It is a
positive integer. `published_case_count` is the non-negative integer sum of
their `source_case_count` values. A `published_case_share` is the unrounded
ratio of one aggregate's `published_case_count` to the total
`published_case_count` of the full input scope. Its denominator includes every
input row, including unknown geography and unspecified age. If that denominator
is zero, all shares in the corresponding share table are `NA`.

## Artifacts

### National weekly table

- **Path:** `artifacts.analysis_weekly_national`
- **Question:** How are published dengue records distributed by source week in
  the primary scope?

```text
analysis_table_schema_version
analysis_scope_id
source_resource_id
source_year
source_week
published_row_count
published_case_count
```

Logical key: `(analysis_scope_id, source_resource_id, source_year, source_week)`.
Rows are ordered by `source_year`, then `source_week`, ascending. The table
contains only weeks represented by at least one input row; no absent week means
zero cases.

### Provincial summary

- **Path:** `artifacts.analysis_province_summary`
- **Question:** How are published dengue records distributed among reported
  provincial categories?

```text
analysis_table_schema_version
analysis_scope_id
source_resource_id
source_year
province_id
province_name
published_row_count
published_case_count
published_case_share
```

Logical key:
`(analysis_scope_id, source_resource_id, source_year, province_id, province_name)`.
Rows are ordered by `source_year`, `province_id`, then `province_name`,
ascending. Before derivation, every non-missing `province_id` must map to at
most one `province_name` within the input scope. A conflict aborts rather than
normalizing or choosing a name.

The published category `province_id = "99"`, `province_name = "desconocida"`
is retained when present. It contributes to the full-scope denominator.

### Provincial weekly table

- **Path:** `artifacts.analysis_weekly_province`
- **Question:** How are published dengue records distributed over time within
  reported provincial categories?

```text
analysis_table_schema_version
analysis_scope_id
source_resource_id
source_year
source_week
province_id
province_name
published_row_count
published_case_count
```

Logical key:
`(analysis_scope_id, source_resource_id, source_year, source_week, province_id, province_name)`.
Rows are ordered by `source_year`, `source_week`, `province_id`, then
`province_name`, ascending. No full province-week grid is constructed.

### Source-age-group summary

- **Path:** `artifacts.analysis_age_group_summary`
- **Question:** What is the published composition by source age-group category?

```text
analysis_table_schema_version
analysis_scope_id
source_resource_id
source_year
source_age_group_id
source_age_group_label
published_row_count
published_case_count
published_case_share
```

Logical key:
`(analysis_scope_id, source_resource_id, source_year, source_age_group_id, source_age_group_label)`.
Before derivation, every non-missing `source_age_group_id` must map to at most
one `source_age_group_label`. A conflict aborts rather than recoding labels.
The producer parses a temporary copy of each source ID only to require strict
decimal integers and order them numerically; it never changes the textual ID
written to the artifact. Rows are ordered by `source_year`, numeric source
age-group ID, then source label, ascending.

`Sin Especificar`, any other published unspecified category, and source text
such as `dÍas` are retained literally and included in the share denominator.

## Reconciliation invariants

For every one of the four artifacts:

```text
sum(published_row_count)  == number of input scope rows
sum(published_case_count) == sum(input source_case_count)
```

Every logical key is unique. `published_row_count` values are positive
integers; `published_case_count` values are non-negative integers. In each
share table, values are in `[0, 1]` or all `NA` only when the full-scope count
total is zero. With a positive denominator, shares sum to one within an
absolute tolerance of `1e-12`.

## Publication and version control

The producer constructs and validates all four tables in memory before
publishing any artifact. It writes each complete table to a controlled
temporary file in its configured output directory, then atomically renames it
to the final path. A publication failure identifies the affected artifact,
does not modify inputs, and cleans only controlled temporary files. This
version provides atomic publication per artifact, not a multi-artifact
transaction.

All four CSVs are regenerable processed data and ignored by Git. The script,
this contract, and configured output paths are versioned.

## Blocking errors

Execution aborts before publication if configuration is invalid; input is
missing, malformed, or incompatible; scope, resource, or year composition is
not singular; event composition is not singular; input provenance or numeric invariants fail; province or
age-group mappings are ambiguous; a table schema, key, reconciliation, share,
or order is invalid; or a temporary write or atomic publication fails.
