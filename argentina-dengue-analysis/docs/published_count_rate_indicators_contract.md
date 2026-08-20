# Published count-rate indicators contract

## Identity

- Contract ID: `published_count_rate_indicators`
- Version: `1.0.0`
- Producer: `scripts/analysis/16_build_published_count_rate_indicators.R`

## Purpose and scope

This contract publishes descriptive `published_count_rate_100k` indicators by
combining already aggregated C.12 published counts, official C.14 population
denominators, and C.15 geographic mapping evidence. It does not identify
unique people, estimate incidence, correct surveillance coverage, or produce
seasons, models, figures, or dashboard data.

## Inputs

The producer consumes only:

- C.12 national weekly, province summary, and province weekly artifacts;
- C.14 `population_denominators.csv`;
- C.15 source-geography and province-region crosswalks; and
- C.15 geographic mapping validation snapshot.

It never reconstructs C.12 aggregates from C.11 scopes and never reads raw
data.

## Denominator scenarios

`contemporary` uses Censo 2010 for 2018 and Censo 2022 for 2022, 2024, and
2025. `sensitivity_interannual` uses Censo 2010 for every source year. The
policy is configured in `project.yml`.

Both scenarios are retained even when they resolve to the same vintage (as
they do for 2018), because scenario identity is an analytical policy rather
than a guarantee of distinct numerical values.

## Artifacts and common fields

The contract publishes six regenerable artifacts in `data/processed/`:

- `epidemiology_national_summary.csv`
- `epidemiology_weekly_national.csv`
- `epidemiology_province_summary.csv`
- `epidemiology_weekly_province.csv`
- `epidemiology_region_summary.csv`
- `epidemiology_weekly_region.csv`

All contain the schema version, scope, source year/resource, denominator
scenario, projection vintage, population reference date, and rate-period
basis. `published_count_rate_100k` is exactly
`100000 * published_case_count / population`. It is not an incidence, risk,
attack rate, or person-level measure.

## Grains and fields

National summary has grain `analysis_scope_id + denominator_scenario` and
adds published row/case counts, national population, rate, observed week
count, and exact ordered observed week set. National weekly additionally has
`source_week` in its grain and publishes the same count/population/rate
measure at that grain.

Province summary has grain `analysis_scope_id + denominator_scenario +
reference_province_id`; province weekly adds `source_week`. Both publish
reference province identity, counts, province population, and rate. Province
summary also publishes national case share and scope-level geographic mapping
completeness.

Region summary has grain `analysis_scope_id + denominator_scenario +
epidemiological_region`; region weekly adds `source_week`. Regional population
is the sum of official province denominators for every jurisdiction in the BEN
region, regardless of whether that jurisdiction has an observed numerator row.
The summary also contains
national case share and mapping completeness.

## Week coverage

`rate_period_basis` is `observed_weeks_01_52` only when the observed C.12 week
set is exactly W01 through W52; otherwise it is `observed_week_subset`. This
is an observation statement, not a claim of complete epidemiological-year
surveillance.

## Geographic policy

National outputs retain all C.12 published counts, including unknown,
ambiguous, and unmapped geography. Province and region outputs are published
only for C.15 scopes marked `supported_with_caveats`, and use only
`documented_exact` or `validated_exact` mappings. Unmapped, unknown,
ambiguous, and name-based unverified records never become artificial zero
rows. Provincial and regional shares can therefore sum to less than one.

## Validation and publication

Before publication, the producer validates input schemas, scenario policy,
finite non-negative rates, output grains, national weekly-to-summary
reconciliation, C.15 mapped-province reconciliation, weekly-to-summary
province reconciliation, and province-to-region reconciliation. Each
artifact is written to a temporary in its destination directory and atomically
renamed. The six artifacts are regenerable and ignored by Git.
