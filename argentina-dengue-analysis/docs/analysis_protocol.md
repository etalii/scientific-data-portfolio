# Analysis Protocol

## Status and purpose

- **Version:** 1.0
- **Status:** completed descriptive portfolio scope
- **Project:** Argentina Dengue Surveillance

This protocol defines the methodological boundary of the completed portfolio
analysis. It documents a reproducible public-health surveillance data workflow,
not an official epidemiological reporting system.

## Analytical question

> How were published Dengue counts distributed over source weeks, reported
> provincial categories, and reported age categories in the explicit 2024
> primary scope?

The question is intentionally descriptive. It does not ask about incidence,
risk, unique people, causal mechanisms, or a directly comparable 2018–2025
trend.

## Source and primary scope

The source is the Argentine Ministry of Health dataset *Vigilancia de las
enfermedades por virus del Dengue y Zika*, published through Datos Argentina.

The configured primary scope is:

- source year: 2024;
- source event: Dengue;
- one canonical resource selected by the documented resource-level policy.

The general Dengue event is not combined with Dengue durante la gestación; the
available documentation does not establish event exclusivity. Zika is outside
this portfolio scope.

## Design principles

- Preserve raw files and source-row provenance.
- Separate integrity validation, canonical resource selection, structural
  harmonization, quality assessment, analytical selection, aggregation, and
  visualization.
- Preserve uncertainty when the evidence does not justify a corrective
  transformation.
- Treat source-case-count aggregates as published counts, not reconstructed
  individual cases.
- Keep the analysis scope explicit in configuration.

## Pipeline

~~~text
CKAN metadata
  → immutable download and provenance log
  → local integrity/provenance/readability validation
  → resource-level canonical selection
  → structural harmonization
  → quality assessment without correction
  → primary scope selection
  → deterministic published-count tables
  → descriptive portfolio figures
~~~

The detailed implementation and hand-off invariants are defined in the
project's versioned contracts and [architecture document](project_architecture.md).

## Descriptive outputs

The completed scope produces:

- national weekly published counts;
- published-count rankings of reported provincial categories;
- observed weekly dynamics for the five highest-count known jurisdictions;
- published-count composition by source-reported age category.

No absent source week or province-week is completed with zero. Source labels,
including dÍas and Sin Especificar, are retained as published.

## Interpretation limits

- Counts do not represent deduplicated people.
- Population denominators are unavailable; no incidence or risk estimates are
  produced.
- Exact duplicates and visible-dimension count conflicts are preserved because
  their error status is not established.
- Unknown geography is retained and not redistributed.
- Heterogeneous schemas, coverage, and semantic evidence do not support a
  direct interannual 2018–2025 comparison.
- The temporal pattern is descriptive and does not attribute causes.

## Future work

Any report, spatial display, population-adjusted analysis, additional event
scope, or interannual comparison must be introduced by a separate documented
policy. It must not be inferred from the current structural pipeline.
