# Structural Harmonization Contract

## Contract identity

- **Contract ID:** `structural_harmonization`
- **Version:** `1.0.0`
- **Producer:** `scripts/processing/04_harmonize_canonical_resources.R`
- **Artifact:** `data/processed/canonical_resources_structural.csv`

## Purpose and scope

This contract represents canonical source resources in one common tabular
structure while retaining source meaning and provenance. It is a structural
mapping only. It does not assert that fields from distinct source-schema
families are epidemiologically equivalent.

The producer does not deduplicate, filter events, select dengue, recode age
groups, normalize or correct geography or text, aggregate records, complete
weeks, merge observations, or modify raw files.

## Inputs

The producer reads only centrally configured paths from `config/project.yml`:

- `artifacts.canonical_resources` (`canonical_resource_selection` v1.0.0);
- `artifacts.validation_snapshot` (`validation_snapshot` v1.0.0);
- `artifacts.canonical_resources_structural`;
- `directories.raw_data` and `directories.processed_data`;
- `harmonization.body_encodings`.

Only canonical-manifest records with `processing_authorized = TRUE` are in
scope. Each must match exactly one `catalog_resource` validation row by
`resource_id + local_filename`. That row must have `processing_eligible = TRUE`
and `physical_status`, `provenance_status`, and `readability_status` equal to
`passed`; its `csv_delimiter` must be `comma`, `semicolon`, or `tab`.

The validation snapshot is the sole delimiter authority. The producer never
redetects a delimiter.

## Full-payload decoding

The producer reads all source fields initially as text. It determines decoding
from the complete logical CSV payload:

1. If the payload is valid UTF-8, use `UTF-8`.
2. Otherwise, use the configured fallback `latin1`.
3. No other encoding may be tried, and appearance must not influence the
   decision.

Decoding interprets bytes; it does not repair mojibake, accents, spelling,
capitalization, Unicode, geography, or age labels. Text values in the output
are exactly the decoded source values.

### Terminal transport marker

A single byte `0x1A` may be excluded from the in-memory logical payload only
when it is the sole `0x1A`, is exactly at EOF, immediately follows the newline
terminator of the final CSV record, and has no following bytes. It is a
transport marker, not a CSV record. Any other occurrence, multiplicity, or
placement of `0x1A` aborts execution. Raw files are never changed.

`source_row_number` is the 1-based ordinal of a logical parsed CSV data record,
excluding the header; it is not a physical line number.

## Source-schema families

`source_schema_family` is determined exclusively from the exact ordered source
column signature. Extra, missing, duplicated, or reordered columns are not
accepted by this version.

### `generic_geography`

The exact signature is:

```text
departamento_id, departamento_nombre, provincia_id, provincia_nombre,
{ano | año}, semanas_epidemiologicas, evento_nombre, grupo_edad_id,
grupo_edad_desc, cantidad_casos
```

Exactly one year-column alternative must be present.

### `indec_residence_geography`

The exact signature is:

```text
id_depto_indec_residencia, departamento_residencia,
id_prov_indec_residencia, provincia_residencia, anio_min, evento,
id_grupo_etario, grupo_etario, sepi_min, cantidad
```

Zero or multiple matching families abort execution.

## Structural mapping

| Output field | `generic_geography` | `indec_residence_geography` |
| --- | --- | --- |
| `province_id` | `provincia_id` | `id_prov_indec_residencia` |
| `province_name` | `provincia_nombre` | `provincia_residencia` |
| `department_id` | `departamento_id` | `id_depto_indec_residencia` |
| `department_name` | `departamento_nombre` | `departamento_residencia` |
| `source_year` | `ano` or `año` | `anio_min` |
| `source_week` | `semanas_epidemiologicas` | `sepi_min` |
| `event` | `evento_nombre` | `evento` |
| `source_age_group_id` | `grupo_edad_id` | `id_grupo_etario` |
| `source_age_group_label` | `grupo_edad_desc` | `grupo_etario` |
| `source_case_count` | `cantidad_casos` | `cantidad` |

`source_year` and `source_week` identify corresponding published structural
positions only; this contract does not assert that the `_min` columns have a
fully documented semantic equivalence to historical columns. Likewise,
`source_case_count` does not assert epidemiological comparability of the two
source count fields.

## Schema

Rows are sorted by `source_resource_id`, then `source_row_number`. Empty source
text fields are written as empty CSV fields.

| Column | Type | Nullable | Description |
| --- | --- | --- | --- |
| `source_resource_id` | string | No | Canonical source resource ID. |
| `source_local_filename` | string | No | Raw filename from the canonical manifest. |
| `source_row_number` | positive integer | No | 1-based logical source-record ordinal. |
| `source_schema_family` | string | No | `generic_geography` or `indec_residence_geography`. |
| `province_id` | string | Yes | Decoded source value; never padded or recoded. |
| `province_name` | string | Yes | Decoded source value; never corrected. |
| `department_id` | string | Yes | Decoded source value; never padded or recoded. |
| `department_name` | string | Yes | Decoded source value; never corrected. |
| `source_year` | integer | No | Source year position, validated from 1000 through 9999. |
| `source_week` | integer | No | Source week position, validated from 1 through 53. |
| `event` | string | Yes | Decoded source event value. |
| `source_age_group_id` | string | Yes | Source age-group code, not a canonical code. |
| `source_age_group_label` | string | Yes | Source age-group label, not recoded. |
| `source_case_count` | non-negative integer | No | Source count position, without cross-family comparability assertion. |

The logical key is `(source_resource_id, source_row_number)`. Geographic
identity is provisional and scoped to
`(source_schema_family, province_id, department_id)`; `department_id` is never
a global geographic key.

## Validation and preservation invariants

- Every logical input CSV data record produces exactly one output row.
- No input record is removed, duplicated, added, merged, aggregated, or
  reordered within its source resource.
- `source_row_number` starts at 1 for each resource.
- Total output rows equal the sum of logical source-record counts.
- The logical key is unique.
- `source_year`, `source_week`, and `source_case_count` are strict decimal
  integers; week is 1--53 and count is non-negative.
- Raw files and the canonical manifest remain unchanged.

## Publication and version control

The producer validates all inputs and invariants before writing. It writes the
complete artifact to a project-owned temporary file in the configured processed
directory and atomically renames it into place. A failure leaves a previous
artifact unchanged and cleans only its own controlled temporary file.

The processed CSV is regenerable and ignored by Git. The script, configuration,
and this contract are versioned.

## Blocking errors

Execution aborts before publication for invalid configuration or contracts;
missing or incompatible validation evidence; missing raw files; unsupported
delimiter; invalid terminal `0x1A`; decoding or CSV parsing failure; an unknown
or ambiguous schema family; schema drift; invalid numeric fields; a failed
cardinality or key invariant; or failed atomic publication.
