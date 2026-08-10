# Validation Snapshot Contract

## Contract identity

- **Contract ID:** `validation_snapshot`
- **Version:** `1.0.0`
- **Artifact:** `data/metadata/validation_snapshot.csv`
- **Producer:** `scripts/validation/02_validate_downloads.R`
- **Primary consumer:** a future canonical resource-selection stage

## Purpose and scope

`validation_snapshot.csv` records the current local validation state of every
catalog resource and of every unattributed final file found in `data/raw/`.
It verifies physical integrity, attributable provenance and basic CSV
readability. It does not clean, transform, interpret, select or merge data.

The artifact is a current-state snapshot, not a deterministic artifact: its
run identifier and timestamp change on every successful execution. It is an
operational derived artifact, is not versioned in Git, and must not be edited
manually.

## Inputs and exclusive execution

The producer consumes only `config/project.yml`, `resources_catalog.csv`
(`resources_catalog` v2.0.0), `download_log.csv` (`download_log` v1.0.0), and
local final files in the configured raw-data directory. It never queries CKAN
or a remote URL.

The producer acquires `artifacts.acquisition_validation_lock` atomically before
reading the catalog, download log or raw-data directory. `01_download_data.R`
uses the same lock. Therefore, acquisition and validation never run
simultaneously in one workspace.

## Current provenance reconstruction

For each catalog resource, the contractual identity is:

```text
resource_id + download_url + local_filename + destination_path
```

where `destination_path` is the configured raw-data directory plus
`local_filename`.

Only `resource_result` events with outcome `downloaded` or
`skipped_existing_verified` and an exact matching identity are candidates for
current provenance. Historical failed events never provide provenance and do
not by themselves invalidate current provenance.

Candidate successes are grouped by `(file_size_bytes, sha256)`:

- zero groups produce `provenance_missing`;
- one group produces valid provenance; the last physical CSV row in that group
  is the current evidence event, while `provenance_evidence_count` records all
  compatible successful events;
- more than one group produces `provenance_conflict`.

Successful events with an incompatible historical identity remain historical
evidence. They do not invalidate an exact current evidence group merely because
they exist. When no exact current group exists, the current result is
`provenance_missing`; an incompatible historical event does not become a
surrogate for the current identity. This contract deliberately does not infer a
resource-update policy from historical events.

## Validation levels

### Physical integrity

For an in-scope resource with valid provenance, validation checks existence,
regular-file status, positive size, exact size equality and exact SHA-256
equality. `local_filename` must agree among catalog, provenance event and
filesystem path.

### Provenance

A resource is attributable only when exactly one compatible successful payload
group exists for its current contractual identity. A raw file that cannot be
attributed to a catalog resource and compatible provenance event is reported as
an unattributed raw-file record and never becomes processing-eligible.

### Basic CSV readability

For a CSV resource, the validator detects an unambiguous delimiter from comma,
semicolon and tab candidates, with quoted fields respected. It confirms the
candidate using the header and a small tabular sample read as character data.
The detected delimiter must yield a parseable non-empty header and at least two
columns. It does not normalize names, infer types, validate epidemiological
variables, or validate the complete dataset. A BOM is tolerated; encoding is
not inferred or transformed unless it prevents structural validation.

A parseable header with zero data rows is physically valid but yields
`valid_with_warning` and diagnostic `csv_no_data_rows`. It never becomes
processing-eligible until a later stage explicitly defines a policy for empty
datasets.

## Preflight

The validation run aborts without replacing an existing snapshot when any of
the following occur:

- configuration, catalog or download log violates its contract;
- the shared acquisition-validation lock cannot be acquired;
- the raw-data directory cannot be read;
- a project-owned residual publication temporary is present in `data/raw/`;
- the validation snapshot cannot be written and atomically published.

Per-resource validation failures do not abort the run. They are represented in
the snapshot and prevent only the affected resource from becoming
processing-eligible.

## Schema

The logical key is `(record_type, record_key)`. Rows are sorted by those fields
for stable content apart from run metadata.

| Column | Type | Nullable | Description |
| --- | --- | --- | --- |
| `validation_schema_version` | string | No | Constant `1.0.0`. |
| `validation_run_id` | string | No | Opaque identifier for this validation execution. |
| `validated_at_utc` | ISO 8601 UTC string | No | Time at which the row was validated. |
| `record_type` | string | No | `catalog_resource` or `raw_file_unattributed`. |
| `record_key` | string | No | `resource_id` for catalog rows; filename for unattributed files. |
| `resource_id` | string | Yes | Catalog resource identifier. Required for catalog rows. |
| `eligible_for_download` | boolean | Yes | Current technical eligibility from the catalog. |
| `download_url` | string | Yes | Current catalog URL. |
| `local_filename` | string | Yes | Current catalog filename or observed unattributed filename. |
| `destination_path` | project-relative path | Yes | Expected or observed raw-data location. |
| `provenance_event_type` | string | Yes | Current `downloaded` or `skipped_existing_verified` event. |
| `provenance_run_id` | string | Yes | Run that produced current evidence. |
| `provenance_event_at_utc` | ISO 8601 UTC string | Yes | Time of current evidence. |
| `provenance_evidence_count` | non-negative integer | Yes | Count of compatible successful events. |
| `expected_file_size_bytes` | positive integer | Yes | Size from current provenance. |
| `expected_sha256` | lowercase SHA-256 | Yes | Checksum from current provenance. |
| `observed_file_size_bytes` | non-negative integer | Yes | Size observed locally. |
| `observed_sha256` | lowercase SHA-256 | Yes | Checksum observed locally. |
| `physical_status` | string | No | `passed`, `failed` or `not_applicable`. |
| `provenance_status` | string | No | `passed`, `failed` or `not_applicable`. |
| `readability_status` | string | No | `passed`, `warning`, `failed` or `not_applicable`. |
| `csv_delimiter` | string | Yes | Detected CSV delimiter: `comma`, `semicolon` or `tab`. |
| `csv_column_count` | positive integer | Yes | Columns observed during basic CSV validation. |
| `validation_outcome` | string | No | `valid`, `valid_with_warning`, `invalid` or `not_applicable`. |
| `diagnostic_code` | string | No | Primary controlled diagnostic. |
| `processing_eligible` | boolean | No | Technical handoff decision for a later stage. |

`record_type` values are `catalog_resource` and `raw_file_unattributed`.
`provenance_event_type` is nullable, otherwise `downloaded` or
`skipped_existing_verified`. Null values are written as empty CSV fields.

`diagnostic_code` values are:

- `none`
- `missing_file`
- `not_regular_file`
- `empty_file`
- `size_mismatch`
- `sha256_mismatch`
- `provenance_missing`
- `provenance_conflict`
- `csv_unreadable`
- `csv_missing_header`
- `csv_delimiter_undetermined`
- `csv_no_data_rows`
- `raw_file_unattributed`
- `not_currently_eligible`

## Outcome and handoff policy

`processing_eligible` is `TRUE` only for a `catalog_resource` that is currently
eligible for download, has passed physical and provenance checks, and has
passed basic readability without warnings. It is not an epidemiological or
canonical selection decision.

Currently ineligible catalog resources with an attributable raw file may be
reported as `valid` but always have `processing_eligible = FALSE` and
diagnostic `not_currently_eligible`. A resource with no current eligibility and
no local file is `not_applicable`.

The future canonicalization stage must decide which technically valid resources
are suitable for analysis before any merge. That stage is intentionally outside
this contract.

## Publication policy

The producer constructs a complete snapshot, writes it to a temporary file in
the same directory as the configured artifact, and atomically renames it into
place. A failed preflight or publication leaves the prior snapshot unchanged.
