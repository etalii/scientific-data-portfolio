# Multiyear Dengue Scope Contract

## Contract identity

- **Contract ID:** `multiyear_dengue_scope`
- **Version:** `1.0.0`
- **Producer:** `scripts/processing/11_build_multiyear_dengue_scopes.R`
- **Artifact:** `data/processed/multiyear_dengue_scopes.csv`

## Purpose

This contract creates one row-preserving Dengue scope per configured canonical
source year. It reads only `structural_harmonization` v1.0.0 and selects rows
where `event` equals the configured value. It does not alter the existing
`primary_dengue_2024` scope.

## Schema

The artifact contains `multiyear_scope_schema_version`, `analysis_scope_id`,
then the exact ordered fourteen structural-harmonization fields. The version is
always `1.0.0`; the scope ID is `dengue_<source_year>`.

## Invariants

- Each configured year is non-empty and contains exactly one resource.
- Every and only matching Dengue row is retained once, in source-resource and
  source-row order.
- No duplicates, count conflicts, unknown geography, source labels, or absent
  weeks are resolved or created.
- The 2024 scope must be structurally equivalent to the existing primary scope
  when both use the same event and year.

The artifact is regenerable processed data and is ignored by Git.
