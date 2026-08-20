# Epidemiological season scope contract

## Identity

- Contract ID: `epidemiological_season_scope`
- Version: `1.0.0`
- Producer: `scripts/processing/17_build_epidemiological_season_scope.R`
- Material input: `multiyear_dengue_scopes.csv` from C.11

## Purpose

This contract creates a deterministic temporal selection of published Dengue
rows whose source-year/week tuples match the configured epidemiological-season
window. It does not establish complete surveillance, incidence, a population
denominator, or a cumulative seasonal rate.

## Configuration and expected tuples

The scope identifier, label, event, and ordered source-year/week segments are
defined in `project.yml`. The expected tuple set is generated in configuration
segment order. For v1.0.0 it is 2024 W31--W52 followed by 2025 W01--W30.

`season_week_index` is the one-based position of a tuple in that configured
set. It never replaces `source_year` or `source_week`, and no source week is
converted to a Gregorian or ISO date.

Configuration must define non-empty identifiers and event, valid integer years
and weeks, non-empty segments, and a unique tuple set. Duplicate configured
tuples abort execution.

## Output

`data/processed/dengue_season_2024_2025_rows.csv` is regenerable and ignored
by Git. Its first columns are:

```text
season_scope_schema_version
season_scope_id
season_label
season_week_index
```

They are followed by the exact ordered sixteen C.11 fields:

```text
multiyear_scope_schema_version
analysis_scope_id
source_resource_id
source_local_filename
source_row_number
source_schema_family
province_id
province_name
department_id
department_name
source_year
source_week
event
source_age_group_id
source_age_group_label
source_case_count
```

The annual C.11 `analysis_scope_id` remains present to preserve lineage to
both annual source scopes. No synthetic resource identifier is created.

## Coverage gate and preservation

The producer validates the unique selected `(source_year, source_week)` set
against the expected tuple set and calculates expected, observed, missing, and
unexpected tuple counts. Controlled coverage statuses are:

- `complete_expected_week_set`
- `incomplete_expected_week_set`
- `unexpected_week_set`

Publication requires `complete_expected_week_set`; missing tuples abort before
publication. No absent week is represented as zero, imputed, or interpolated.
Rows outside the configured window are ordinary outside-scope rows, not
unexpected weeks.

Every output row is the unchanged matching C.11 row plus the four season
fields. Counts, source geography including unknown categories, age fields,
source text, duplicates, and conflicts are preserved. The scope must contain
one structural family, but that continuity alone does not establish complete
epidemiological comparability.

## Validation snapshot

`data/metadata/epidemiological_season_scope_snapshot.csv` is deterministic
methodological metadata and is versioned in Git. It has one row per season
scope and records coverage, the single observed structural family, deterministic
source-resource topology, row count, and published-count reconciliation. It
does not certify surveillance completeness, geographic completeness, incidence,
or denominator validity for a seasonal cumulative rate.

## Dependencies and future work

C.17 reads neither C.12--C.16, population data, C.15 mappings, nor raw files.
It does not modify C.13. C.18 must assess geographic completeness within this
specific temporal window rather than reuse annual C.15 completeness. It must
also define an explicit policy before publishing any cumulative seasonal rate;
weekly indicators may require source-year-specific denominators.

## Publication

Both artifacts are fully built and validated before publication. Each is
written to a project-owned temporary in its destination directory and
atomically renamed. Output rows are deterministically ordered by
`season_week_index`, `source_resource_id`, and `source_row_number`.
