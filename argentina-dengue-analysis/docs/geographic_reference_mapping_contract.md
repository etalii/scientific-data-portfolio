# Geographic reference mapping contract

- Contract ID: `geographic_reference_mapping`
- Version: `1.0.0`
- Producer: `scripts/reference/15_build_geographic_references.R`

## Purpose

C.15 derives the jurisdiction IDs and denominator-coverage validation from C.14,
uses the documented official INDEC geographic reference for canonical names, maps
observed source-province categories without changing source values, joins the
approved BEN regionalization through that reference, and measures mapping
coverage for the four multiyear Dengue scopes. It does not calculate rates,
change source data, select a population vintage, or build a regional population.

## Artifacts

The versioned artifacts are `data/metadata/province_reference.csv`,
`source_geography_crosswalk.csv`, `province_region_crosswalk.csv`, and
`geographic_mapping_validation_snapshot.csv`.

The province reference has `province_reference_schema_version`,
`reference_province_id`, `reference_province_name`, `reference_system`, and
`source_authority`, plus `population_source_label` and
`population_source_label_status` as diagnostics. Canonical IDs and names come
from the configured official INDEC CODGEO reference. Every C.14 vintage/year
must contain the same 24 reference IDs; workbook labels are evidence only and
may be marked `population_source_label_mismatch`. In particular, the published
C.14 label `SANTE FE` for ID `82` is retained diagnostically while the canonical
reference remains `Santa Fe`.

The source crosswalk has `source_geography_crosswalk_schema_version`,
`source_schema_family`, `source_province_id`, `source_province_name`,
`reference_province_id`, `reference_province_name`, `mapping_status`,
`mapping_basis`, and `source_geography_semantics_status`. Its key is the first
three fields. Source strings are retained literally. Comparison may case-fold
Unicode text only; it never removes accents, repairs spelling, or fuzzy-matches.

`mapping_status` is one of `documented_exact`, `validated_exact`,
`name_based_unverified`, `ambiguous`, `unknown_source_category`, or `unmapped`.
`99` / `desconocida` is recognized only in `indec_residence_geography` and is
`unknown_source_category`. `generic_geography` remains
`source_geographic_semantics_undocumented`; the modern family is
`field_name_supports_residence_but_operational_semantics_undocumented`.

The BEN regional crosswalk has `region_crosswalk_schema_version`,
`reference_province_id`, `reference_province_name`, `epidemiological_region`,
`source_authority`, `source_document`, `source_url`, and `effective_context`.
It maps each of the 24 reference jurisdictions exactly once. Unknown and
unmapped source categories never receive a region directly.

The validation snapshot has one row per `analysis_scope_id + source_year` and
the schema specified in `config/project.yml` producer. It reports counts for
mapped (`documented_exact` or `validated_exact`), name-based, ambiguous,
unmapped, and unknown records separately. Completeness is mapped published
case count divided by total published case count. It publishes
`supported_with_caveats` only when all known categories are technically mapped;
otherwise it is `unsupported`. Ordered reason codes are pipe-delimited.
