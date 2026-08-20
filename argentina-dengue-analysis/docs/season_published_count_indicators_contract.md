# Season published-count indicators contract

- Contract ID: `season_published_count_indicators`
- Version: `1.0.0`
- Producer: `scripts/analysis/18_build_season_published_count_indicators.R`

C.18 consumes only the C.17 season scope and snapshot, C.14 population
denominators, and C.15 geographic and BEN crosswalks. It re-evaluates mapping
within the season; annual C.15 completeness is not reused.

It publishes six ignored, regenerable indicator CSVs and the versioned
`season_geographic_validation_snapshot.csv`. National, province, and region
summaries publish cumulative published counts only, without scenario
duplication or a cumulative rate. Weekly national, province, and region
artifacts publish both configured scenarios and use the denominator matching
each row's `source_year` and projection vintage.

The geographic snapshot classifies every season row as exact mapped,
name-based, ambiguous, unmapped, or unknown. Only exact mappings enter
territorial numerators; unknown and all other nonassignable rows are never
redistributed. Territorial summaries can therefore sum below the national
total.

Regional denominators come only from a validated in-memory lookup keyed by
`source_year + denominator_scenario + epidemiological_region`. Each regional
population sums every official BEN component province, irrespective of weekly
observations. `region_observed_province_fraction` describes the fraction of
component provinces with mapped rows in a region-week; absence is not zero and
does not alter numerators or denominators.

v1.0.0 adopts Option E: no cumulative season
`published_count_rate_100k` is published. Cumulative counts are valid sums of
published rows, but no single seasonal denominator policy is defined. Weekly
rates are not summed into a cumulative rate.
