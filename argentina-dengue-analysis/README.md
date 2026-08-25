# Argentina Dengue Surveillance

**A contract-first, reproducible analysis of official Argentine dengue surveillance data.**

This portfolio shows how verified published counts, population denominators,
and explicit analytical-scope rules can produce transparent descriptive
evidence—without overstating incidence, individual risk, or surveillance
completeness.

> **[Read the full portfolio report →](https://etalii.github.io/scientific-data-portfolio/argentina-dengue-analysis/)**

## Companion ecological perspective

A hypothesis-driven population-ecology interpretation of the certified
surveillance patterns, linking seasonal and spatial results to *Aedes aegypti*
ecology, DENV transmission biology, human population processes, and
surveillance limitations.

> **[Companion ecological perspective →](https://etalii.github.io/scientific-data-portfolio/argentina-dengue-analysis/ecological-perspective/)**

## Two analytical scopes

### Season — SE31/2024–SE30/2025

Used for the national temporal profile and regional observed timing.

### Calendar year 2024

Used for province count/rate comparisons and BEN-region population-adjusted
comparisons.

These analytical periods are distinct and are not treated as interchangeable.

## Headline finding: population adjustment changes territorial ordering

**Calendar year 2024 · contemporary denominator scenario**

![Rank shifts between published counts and published-count rates per 100,000 across Argentine provinces in calendar year 2024. Buenos Aires moves from rank 1 to 16, while Tucumán moves from rank 3 to 1.](figures/province_count_rate_rank_shift_2024_en.png)

*Published-count rates per 100,000 are descriptive population-adjusted
measures, not incidence or individual risk.*

## Key findings

### Season SE31/2024–SE30/2025

- The certified seasonal scope contains **17,844 published counts**, with an
  observed national peak at **SE36**.
- The shortest observed windows containing 50%, 80%, and 90% of published
  counts span **5, 10, and 12 weeks**; geographic mapping completeness is
  approximately **96.2%**.

### Calendar year 2024

- Buenos Aires moves from rank **1** by published count to rank **16** by
  published-count rate; Tucumán moves from **3** to **1**.
- Centro has the largest regional published count, while NOA has the largest
  published-count rate.

## Supporting seasonal view

**Season SE31/2024–SE30/2025**

![National published counts by season week for SE31/2024–SE30/2025, showing the observed peak at SE36 and the 50%, 80%, and 90% concentration windows.](figures/season_national_temporal_profile_en.png)

*Observed seasonal timing of published counts. Missing geographic assignment is
retained rather than redistributed.*

## Why the project is technically distinctive

- Immutable raw-data acquisition with SHA-256 provenance and atomic
  publication.
- Contract-first analytical hand-offs with explicit integrity, provenance, and
  structural validation.
- Reproducible population and geographic references, including an explicit
  denominator sensitivity policy.
- Deterministic R/`renv` execution and a versioned Quarto portfolio report.

## Analytical safeguards

- Published counts are not deduplicated people.
- Published-count rates are not incidence.
- Seasonal and calendar-year analyses use distinct scopes.
- Unknown geography is retained and never redistributed.
- Missing region-week rows are not treated as zero.

The full rationale, findings, and limitations are in the
[portfolio report](reports/argentina_dengue_portfolio.html).

## Reproducibility

### Inspect the analysis

The rendered report can be read without R or Quarto. Technical readers can
[view the report source](reports/argentina_dengue_portfolio.qmd).

### Reproduce the analytical pipeline

The certified render used R 4.1.2; the project declares R >= 4.1. Restore the
project environment from a clean clone:

```r
renv::restore()
renv::status()
```

The pipeline intentionally has no invented master command. Follow the ordered
stages in the [project architecture](docs/project_architecture.md) and the
[analysis protocol](docs/analysis_protocol.md).

### Render the portfolio report

Quarto CLI is external tooling, not an `renv` dependency. It is required only
to render the report, not to read its committed HTML:

```bash
quarto render reports/argentina_dengue_portfolio.qmd
```

## Repository map

```text
config/          Analytical policies and artifact paths
data/metadata/   Versioned provenance and methodological metadata
docs/            Architecture, protocols, contracts, and setup
figures/         Versioned portfolio figures
reports/         Quarto source and rendered report
scripts/         Modular acquisition, processing, analysis, and visualization
```

## Selected documentation

- [Project architecture](docs/project_architecture.md)
- [Analysis protocol](docs/analysis_protocol.md)
- [Environment setup](docs/environment_setup.md)

## Data source and attribution

Surveillance data are official Argentine Ministry of Health releases published
through [Datos Argentina](https://datos.gob.ar/dataset/salud-vigilancia-enfermedades-por-virus-dengue-zika).
The population-adjusted indicators use official INDEC population projections.
Detailed provenance, contracts, and methodological records remain versioned in
[`docs/`](docs/).

## Status

The certified acquisition-to-visualization pipeline and its English Quarto
portfolio report are complete for the current scope. Future extensions require
new, explicitly documented policies.
