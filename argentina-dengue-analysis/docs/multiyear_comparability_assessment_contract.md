# Multiyear Comparability Assessment Contract

## Contract identity

- **Contract ID:** `multiyear_comparability_assessment`
- **Version:** `1.0.0`
- **Producer:** `scripts/analysis/13_assess_multiyear_comparability.R`
- **Artifact:** `data/metadata/multiyear_comparability_snapshot.csv`

## Purpose

The snapshot has one row per canonical source year and resource. It documents
observed Dengue-scope coverage, resource event composition, geographic and age
properties, attributable C.7 evidence, and policy-facing analysis statuses. It
is assessment metadata, not a quality score or a transformation.

## Controlled values

Analysis-status fields use `supported`, `supported_with_caveats`,
`unsupported`, or `pending_reference_data`. Reason-code fields contain
alphabetically ordered controlled codes joined by `|`; no narrative is stored.

`expected_calendar_status` is always `not_defined` in v1.0.0, and expected
week fields are null. Observed week differences are evidence, not a conclusion
of incomplete coverage.

Unknown geography is recognized only for `99` / `desconocida` in the
`indec_residence_geography` family. Earlier-family values are not assumed to
be equivalent and their unknown metrics are null.

All age metrics are prefixed `dengue_` because they are calculated only from
the Dengue scope, not from the complete source resource. In current evidence,
the 2018 resource has 29 source ID/label pairs, while `dengue_2018` has 17;
the other 12 occur only in non-Dengue events. The 17 scope pairs still contain
an ID-to-label inconsistency, so its age semantics remain inconsistent.

## Versioning

The snapshot is deterministic analytical provenance metadata and is versioned
in Git. It reuses C.7 findings by their published provenance and diagnostic
group IDs; it does not recreate C.7 detection algorithms.
