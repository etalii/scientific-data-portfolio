# Population denominator reference contract

## Identity

- Contract ID: `population_denominator_reference`
- Contract version: `1.0.0`
- Producer: `scripts/reference/14_acquire_population_denominators.R`
- Raw inputs: immutable official INDEC population-projection resources
- Outputs:
  - `data/metadata/population_source_provenance.csv`
  - `data/reference/population_denominators.csv`

## Purpose and scope

This contract acquires and validates external population reference data that a
later, separately approved stage may use to calculate published-count rates.
It does not calculate rates, map dengue geographies, build seasons, model data,
or change any existing epidemiological artifact.

Both required projection vintages must pass every acceptance gate before the
normalized denominator artifact is published. C.14 never publishes a partial
denominator table.

## Acquisition modes

The configured official source is attempted online first. If the execution
environment cannot resolve, connect to, or download an official INDEC resource,
the script accepts the user's original, unedited download through the configured
population staging directory.

| `acquisition_mode` | `origin_verification_status` | Meaning |
| --- | --- | --- |
| `online_download` | `official_host_download` | The bytes were downloaded during the execution from a verified official INDEC host. |
| `external_raw` | `external_origin_not_cryptographically_verified` | The user supplied original bytes downloaded externally. Their hash, file structure, and population semantics are validated, but INDEC has not supplied a checksum or signature that would cryptographically prove origin. |

`external_raw` never weakens byte-integrity validation, raw immutability, or
subsequent reproducibility. It must not be a PDF, a transcription, an edited
table, or a file reconstructed from another source.

## Required official source identities

The configuration defines two sources and their official landing pages:

1. `indec_census_2010_projection_2010_2040`, the historical Censo 2010
   provincial projections, for 2018, 2022, 2024, and 2025.
2. `indec_census_2022_projection_2022_2040`, the Censo 2022 provincial
   projections, for 2022, 2024, and 2025. Its selected ingestion source is
   `proyecciones_jurisdicciones_2022_2040_c1.xlsx`.

The Censo 2022 base CSV,
`proyecciones_provinciales_sexo_edad_2022_2040_base.csv`, is an official valid
source but is not an ingestion source in v1.0.0. Its observed grain is
jurisdiction × sex × age group × year and it lacks published national and
explicit both-sexes records. Selecting it would require derived aggregation;
its non-selection status is
`official_source_valid_but_grain_requires_derived_aggregation`.

XLSX and legacy XLS are accepted for the configured C1 sources. PDF is never an ingestion format. An online resolver
must verify an INDEC host, HTTP success, the final download identity and format;
it must never accept an inferred URL merely because it looks plausible. TLS is
never weakened or disabled.

## Raw, staging, and provenance

`outputs/population_staging/` is an ignored operational inbox. C.14 may create
it but never cleans it automatically. It is not a source of truth and no later
stage may consume it.

Accepted bytes are copied unchanged to `data/raw/population/` by a same-filesystem
hidden temporary followed by hash verification and atomic rename. Existing final
raw files are immutable. A rerun accepts them only when their provenance hash
matches exactly; a mismatch aborts. `data/raw/population/` is ignored by Git.

`population_source_provenance.csv` is Git-versioned analytical provenance with
one row per accepted source and these columns, in this order:

| Column | Type | Nullable | Meaning |
| --- | --- | --- | --- |
| `population_provenance_schema_version` | character | no | `1.0.0` |
| `source_resource_identifier` | character | no | configured source identity |
| `projection_vintage` | character | no | controlled configured vintage |
| `acquisition_mode` | character | no | controlled acquisition mode |
| `origin_verification_status` | character | no | controlled origin-verification status |
| `source_authority` | character | no | `INDEC` |
| `source_title` | character | no | configured official title |
| `source_landing_url` | character | no | configured official landing URL |
| `source_download_url` | character | yes | verified effective download URL; absent for an external file whose direct URL cannot be demonstrated |
| `source_format` | character | no | `csv` or `xlsx` |
| `source_sha256` | character | no | lowercase SHA-256 of immutable raw bytes |
| `source_publication_date` | character | yes | official publication date only when supplied by the source |
| `acquired_at_utc` | character | no | first successful raw publication time in UTC |
| `local_filename` | character | no | immutable raw filename, relative to `data/raw/population/` |

`acquired_at_utc` and provenance rows remain unchanged for a verified existing
raw file.

## Validation gates

Both acquisition modes converge before parsing and must satisfy all of the
following: identifiable file; allowed non-PDF format; nonzero size; stable
SHA-256 during the operation; source-specific official schema; correct projection
vintage; total both-sexes population; population at 1 July; all configured years;
one national total and 24 jurisdictions per required year; unique
year/jurisdiction; positive whole-number population; and structural compatibility
with the official documentation. C.14 repairs none of these conditions.

The schema gate is intentionally source-specific and exact. Both currently
configured C1 workbooks must have a `01-TOTAL DEL PAÍS` sheet, exactly 24
province sheets with a two-digit code prefix, and the exact header at row four:
`Año`, `Ambos sexos`, `Varones`, `Mujeres`. The data parser selects only the
published `Ambos sexos` column. It accepts documented blank rows and an INDEC
source-note footer, but aborts on any other layout variation. It validates every
required year in every consumed sheet; it does not derive a national row from
provinces or both-sexes values from the sex-specific columns.

## Normalized denominator artifact

Only after both sources are accepted, C.14 atomically publishes the ignored,
regenerable `data/reference/population_denominators.csv`. Its columns are:

```text
population_schema_version
source_resource_identifier
geography_level
population_year
province_reference_id
province_reference_name
population
population_scope
projection_vintage
census_basis
reference_date
```

`geography_level` is `national` or `province`; national rows have missing
province fields. `population_scope` is always `total_both_sexes`; `reference_date`
is `YYYY-07-01`; and INDEC provincial IDs are two-character text codes. The
required published rows are 100 for the 2010 vintage and 75 for the 2022
vintage when each source contains exactly one national total plus 24
jurisdictions for every required year (175 total). This is a validation outcome,
not a hard-coded output assumption.

## Failure behavior

No failed acquisition, invalid staged file, provenance conflict, or incomplete
pair may alter raw population files, provenance, or denominators. When external
input is required, the script reports for every missing source: official title,
projection vintage, landing URL, documented expected filename when available,
accepted formats, and the exact staging location. The user must provide original
downloaded bytes; C.14 does not request or accept transcription.
