# Canonical Resource Selection Contract

## Contract identity

- **Contract ID:** `canonical_resource_selection`
- **Version:** `1.0.0`
- **Artifact:** `data/metadata/canonical_resources.csv`
- **Producer:** `scripts/processing/03_select_canonical_resources.R`
- **Consumers:** later processing stages, beginning with merge design

## Purpose and scope

`canonical_resources.csv` is a versioned analytical-provenance manifest. It
selects one technically usable source resource for each exactly equivalent
temporal-coverage group. It is a resource-level editorial decision, not a
claim of epidemiological superiority or correctness.

The producer consumes `resources_catalog` v2.0.0 and `validation_snapshot`
v1.0.0. Only catalog-resource records whose `processing_eligible` value is
`TRUE` are in scope. The stage reads only the temporal columns needed to
calculate coverage. It does not modify raw files, merge records, harmonize
schemas, clean data, filter events, or deduplicate observations.

The artifact is versioned in Git. It is deterministic for unchanged inputs:
rows are sorted by `resource_id`, and it contains no run identifier, execution
timestamp, absolute path, or environment-specific value.

## Inputs and preflight

The producer reads paths and policy solely from `config/project.yml`:

- `artifacts.resources_catalog`;
- `artifacts.validation_snapshot`;
- `artifacts.canonical_resources`;
- `directories.raw_data` and `directories.metadata`;
- `canonicalization.header_encodings`;
- `canonicalization.temporal_column_pairs`.

All three artifacts must be project-relative, and the catalog, validation
snapshot, and canonical manifest must belong to the configured metadata
directory. The catalog and validation snapshot must satisfy their respective
contracts before the producer writes a replacement manifest.

## Temporal-header decoding and recognition

The first configured header encoding is the primary encoding and must be
`UTF-8`. The producer inspects only raw header bytes.

1. When those bytes are valid UTF-8, it uses UTF-8 and does not try fallbacks.
2. When they are not valid UTF-8, it tries the remaining configured encodings
   in order. The initial contract uses `latin1` as the sole fallback.
3. After decoding, it compares the resulting column names exactly with the
   configured `year_column` and `week_column` pairs.
4. Exactly one configured pair must be present. Zero or multiple pairs leave
   the resource unresolved.

No transliteration, accent removal, fuzzy or partial matching, position-based
inference, or automatic header correction is permitted. The selected encoding
is also used when reading the two temporal columns. A UTF-8 BOM is tolerated.
The raw file is never rewritten or normalized.

For `pending_ambiguous_coverage`, the producer writes
`selection_status = pending`, `processing_authorized = FALSE`, and leaves all
coverage-derived fields and `competition_count` empty.

## Coverage policy

The producer reads the recognized temporal columns as character data, then
requires each non-missing value to represent an integer year from 1000 through
9999 and an epidemiological week from 1 through 53. It builds the unique set
of valid `(year, week)` pairs, orders it by year then week, and serializes it
as:

```text
YYYY-WW|YYYY-WW|...
```

`coverage_signature` is the lowercase hexadecimal SHA-256 of that UTF-8
serialization. `coverage_week_count` is the actual number of unique pairs.
The start and end fields describe the first and last ordered pairs; they do
not determine coverage equivalence.

An empty or invalid temporal value set is not silently repaired. It leaves the
resource `pending_ambiguous_coverage` because contractual coverage could not
be determined.

## Canonicalization policy

Determined resources are grouped only by `coverage_signature`.

- A one-resource group is `included` with reason `sole_available_resource`,
  `competition_count = 1`, and `processing_authorized = TRUE`.
- In a multi-resource group, `source_last_modified_at` is an editorial,
  reproducible precedence signal from the provider. A unique latest value is
  `included` with reason `selected_latest_source_revision`; other group
  members are `excluded` with reason `superseded_by_latest_source_revision`,
  `processing_authorized = FALSE`, and their
  `superseded_by_resource_id` set to the selected resource.
- If any group member lacks `source_last_modified_at`, all its members are
  `pending` with reason `pending_missing_source_timestamp`.
- If the maximum source timestamp is tied, all its members are `pending` with
  reason `pending_tied_source_timestamp`.

No automatic selection occurs for a pending group. `source_last_modified_at`
is preserved from the catalog without timezone interpretation.

## Schema

The logical key is `resource_id`. Rows are sorted ascending by that key.
Nullable values are written as empty CSV fields.

| Column | Type | Nullable | Description |
| --- | --- | --- | --- |
| `canonical_selection_schema_version` | string | No | Constant `1.0.0`. |
| `resource_id` | string | No | Catalog source-resource identifier. |
| `local_filename` | string | No | Immutable raw filename from the catalog. |
| `coverage_start_year` | integer | Conditional | First ordered coverage year. |
| `coverage_start_week` | integer | Conditional | First ordered coverage week. |
| `coverage_end_year` | integer | Conditional | Last ordered coverage year. |
| `coverage_end_week` | integer | Conditional | Last ordered coverage week. |
| `coverage_week_count` | positive integer | Conditional | Unique observed `(year, week)` count. |
| `coverage_signature` | lowercase SHA-256 | Conditional | Hash of canonical coverage serialization. |
| `source_last_modified_at` | source timestamp string | Yes | Catalog provenance metadata. |
| `competition_count` | positive integer | Conditional | Resources with the same coverage signature. |
| `selection_status` | string | No | `included`, `excluded`, or `pending`. |
| `selection_reason` | string | No | Controlled canonicalization reason. |
| `superseded_by_resource_id` | string | Conditional | Selected resource for an excluded row. |
| `processing_authorized` | boolean | No | Handoff decision for later processing. |

Coverage-derived fields and `competition_count` are nullable only for
`pending_ambiguous_coverage`. They are required and valid for every other
reason. `superseded_by_resource_id` is required only for
`superseded_by_latest_source_revision` and empty otherwise.

`selection_reason` values are:

- `sole_available_resource`
- `selected_latest_source_revision`
- `superseded_by_latest_source_revision`
- `pending_missing_source_timestamp`
- `pending_tied_source_timestamp`
- `pending_ambiguous_coverage`

## Publication policy

The producer constructs the complete manifest, writes it to a temporary CSV
in the same directory as `canonical_resources.csv`, then atomically renames
the temporary file into place. A failed preflight or publication leaves an
existing manifest unchanged.
