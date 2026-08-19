# Dataset Assessment: Historical Preflight

## Status

- **Status:** historical preflight record
- **Scope:** source suitability before the contract-first pipeline was built
- **Current authority:** the versioned pipeline contracts and the completed
  [analysis protocol](analysis_protocol.md)

This document records why the official source was initially selected. It is not
a data dictionary, a claim of interannual comparability, or the specification
for the completed pipeline.

## Source

- **Dataset:** *Vigilancia de las enfermedades por virus del Dengue y Zika*
- **Publisher:** Argentine Ministry of Health
- **Portal:** [Datos Argentina](https://datos.gob.ar/dataset/salud-vigilancia-enfermedades-por-virus-dengue-zika)
- **Published formats:** CSV resources with heterogeneous schemas and encodings

## What the preflight established

The source is official, publicly accessible, geographically national in
coverage, and supplies temporal, geographic, event, age-category, and
published-count fields. Those properties justified building a reproducible
acquisition and assessment workflow.

## What subsequent pipeline evidence changed

The completed pipeline found multiple revisions for the same temporal coverage,
schema drift across releases, heterogeneous file encodings, exact duplicates,
visible-dimension count conflicts, and an unknown geographic category. It
therefore does not assume that all 2018–2025 resources form one comparable
longitudinal series.

For the completed portfolio scope, the analytical question is limited to
published Dengue counts in the explicit 2024 primary scope. See the
[analysis protocol](analysis_protocol.md) and
[project architecture](project_architecture.md).

## Current evidence and limitations

The source is appropriate for the completed descriptive workflow only under its
documented contracts:

- raw resources remain immutable and are verified for integrity and provenance;
- resource-level canonical selection is editorial and reproducible, not a
  statement of epidemiological truth;
- structural harmonization preserves source values and row provenance;
- quality findings are recorded rather than silently corrected;
- published counts are not deduplicated people, rates, or incidence estimates.

No source-only assessment resolves reporting changes, underreporting, or
semantic comparability across years. Any broader comparison, population-based
measure, or additional data integration requires a new documented policy.
