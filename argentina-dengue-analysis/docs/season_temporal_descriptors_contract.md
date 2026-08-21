# Season temporal descriptors contract

Contract ID: `season_temporal_descriptors`. Version: `1.0.0`. Producer:
`scripts/analysis/19_build_season_temporal_descriptors.R`.

C.19 consumes only C.18 season summaries, weekly national/region indicators,
and the season geography snapshot. It publishes ignored, regenerable national
and region summaries plus a national long concentration-window table.

National descriptors use the complete explicit season-week axis. Regional
descriptors use observed region weeks only: absent rows are not zero-filled.
Consequently C.19 publishes no regional concentration windows.

## Reconciliation bases

`season_temporal_national_summary.csv` records the scenario-invariant,
single-numerator base used by its descriptors:

- `national_published_row_count` (integer): sum of C.18 national weekly
  `published_row_count`, once per season week.
- `national_published_case_count` (integer): sum of C.18 national weekly
  `published_case_count`, once per season week.
- `national_observed_week_count` (integer): number of distinct observed
  `season_week_index` values.

These values must reconcile exactly to the C.18 national summary. They are
never calculated by adding contemporary and sensitivity scenario rows.

`season_temporal_region_summary.csv` records the analogous base for each BEN
region:

- `regional_published_row_count` (integer): sum of C.18 regional weekly
  `published_row_count` over its observed weeks, once per week.
- `regional_published_case_count` (integer): sum of C.18 regional weekly
  `published_case_count` over its observed weeks, once per week.
- `regional_observed_week_count` (integer): number of distinct observed
  `season_week_index` values for the region.

Each regional base must reconcile exactly to the corresponding C.18 regional
summary. `regional_temporal_coverage_basis = observed_region_weeks_only`
remains in force; missing regional weeks are not filled.

Count peaks, rate peaks, and unknown peaks use deterministic tie handling:
all tied indices are ascending pipe-delimited and no week is selected on a
tie. Contemporary is the rate descriptor scenario; sensitivity is peak-rate
QA only. Count descriptors are scenario-invariant.

Every field whose name ends in `_tied_season_week_indices` has contractual
type `character`, including a unique peak represented as `"36"`. Tied indices
are serialized in ascending order with `|`, for example `"12|14"`. Consumers
must apply the contractual CSV column type rather than infer it from a value
that happens to contain only digits.

Weighted centers and medians use published counts, never rates. National
50/80/90 percent windows are selected by exhaustive contiguous search: shortest
length, then greatest share, then earliest start. C.19 is descriptive and
does not infer causality, transmission, incidence, onset, or missing zeros.
