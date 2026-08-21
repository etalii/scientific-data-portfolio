# Epidemiological portfolio visualization contract

## Identity

- Contract ID: `epidemiological_portfolio_visualization`
- Version: `1.0.0`
- Producer: `scripts/visualization/20_generate_epidemiological_portfolio_figures.R`

## Purpose and scope

C.20 creates four reproducible, versioned PNG portfolio figures from already
certified C.16, C.18, and C.19 artifacts. It is a presentation stage: it does
not read raw data or row-level scopes, recalculate denominators or aggregates,
fill missing observations, redistribute unknown geography, smooth series, or
make epidemiological causal claims.

The portfolio intentionally contains two non-interchangeable scopes. The two
season figures use the configured `SE31/2024–SE30/2025` scope. The two rate
figures use the configured calendar-year 2024 scope and the `contemporary`
denominator scenario. A figure must visibly label its own scope; metrics from
these two scopes must never share a panel or be presented as the same period.

## Figure artifacts

| Figure ID | Configuration key | Scope | Inputs | Representation |
| --- | --- | --- | --- | --- |
| `season_national_temporal_profile` | `artifacts.season_national_temporal_profile_figure` | Epidemiological season | C.18 weekly national and national summary; C.19 national temporal summary and concentration windows | National published-count season-week line with peak, weighted center, weighted median, and discrete 50/80/90 concentration indicators. |
| `season_regional_observed_timing` | `artifacts.season_regional_observed_timing_figure` | Epidemiological season | C.19 regional temporal summary | Regional multi-descriptor dot plot of observed count peaks, weighted medians, and weighted centers. |
| `province_count_rate_rank_shift_2024` | `artifacts.province_count_rate_rank_shift_2024_figure` | Calendar year 2024 | C.16 province summary | Slopegraph from deterministic published-count rank to deterministic published-count-rate-per-100,000 rank. |
| `region_population_adjusted_burden_2024` | `artifacts.region_population_adjusted_burden_2024_figure` | Calendar year 2024 | C.16 region summary | Coordinated horizontal count and rate panels with one common BEN-region order. |

All outputs are distinct project-relative paths inside `directories.figures`.
They are final portfolio deliverables and are versioned in Git. C.20 creates
no plotting CSVs.

Each figure specification may also be rendered as a localized English variant
at its separately configured `_en` output path. Localization changes only
visible prose, numeric formatting, and human-readable labels. It reuses the
same validated inputs, analytical values, scopes, ordering, ties, geometries,
dimensions, and rendering policy; it is not a new analytical contract or a
new version of the specification.

## Required semantics and caveats

The default render uses Spanish plot text; the localized English render uses
the controlled English prose described above. Contract field names remain
technical. The Spanish render uses `Conteos publicados`, `Tasa de conteos
publicados por 100.000`, `Pico observado`, and `Semana estacional`; the
English render uses their approved localized equivalents. It must not call a
published count rate incidence, risk, a unique-person measure, onset,
transmission, propagation, or duration.

The national season figure states that national published counts retain unknown
and nonassignable geography. Territorial figures state that their numerators
include only geographically mapped published counts and that unknown geography
was not redistributed. Geographic mapping completeness is assignment coverage,
not surveillance completeness.

Regional season descriptors have
`regional_temporal_coverage_basis = observed_region_weeks_only`. Their caption
states that missing region-week rows are not treated as zero. A tied peak is
rendered as every contractually tied season-week index; C.20 must never select
one arbitrary week. Because C.19 peak-province coverage is defined only for a
unique peak, C.20 labels that coverage as unavailable for a tied peak rather
than imputing a fraction.

## Validation

Before constructing any plot, C.20 validates all material input schemas,
schema versions, logical keys, non-missing and finite measures, configured
paths, scope provenance, and denominator scenarios. It validates C.18 national
weekly-to-summary reconciliation and C.19 compatibility with those C.18
inputs, including the complete 1:52 national axis, peak descriptor, temporal
center and median bounds, and concentration-window geometry.

The calendar-year figures require exactly 24 reference provinces and five BEN
regions for the configured calendar year and denominator scenario. Province
ranks use descending measure values with reference province ID as the explicit
tie-break. C.20 validates configured highlighted-province and regional-ranking
expectations from the inputs; they are regression checks, not transformations.

All layouts use deterministic ordering. C.20 builds and validates all four
plots, renders all four controlled temporary PNGs, validates their PNG
signatures, dimensions, and non-zero sizes, then publishes a coherent set with
rollback on controlled publication failure. PNGs use `png(type = "cairo")` at
the configured 150 dpi and fixed dimensions: 2400x1600, 2400x1800,
2400x1800, and 2400x1350 pixels respectively.

## Visual policy

The producer uses a sober white-background theme, generic sans-serif text,
subtle major grids, minimal minor grids, direct labels where needed, and stable
colour semantics supplemented by shape, position, and line type. It does not
use dual axes, rainbow palettes, decorative gradients, 3D, pie charts, or
random layout choices.

## C.10 coexistence

C.20 is an additive v1.1 portfolio layer. The C.10 weekly-national and
province-count-ranking figures remain available as appendix/history; C.10
top-five provincial weekly and age-group figures remain supplementary. C.20
does not move, overwrite, or modify any C.10 figure.
