# Portfolio Descriptive Visualization Contract

## Contract identity

- **Contract ID:** `portfolio_descriptive_visualization`
- **Version:** `1.0.0`
- **Producer:** `scripts/visualization/08_generate_figures.R`

## Purpose and scope

This contract produces four curated, reproducible PNG figures for the
portfolio from the C.9 analysis-table artifacts. They describe **published
counts of Dengue in the `primary_dengue_2024` scope**. They do not represent
unique people, deduplicated cases, incidence, prevalence, risk, or causal
comparisons.

The producer is a presentation stage. It does not read raw data, C.7 quality
findings, C.8 rows, or any upstream source directly. It does not deduplicate,
correct, filter, impute, complete absent province-week combinations with zero,
redistribute unknown geography, recode age labels, or alter an input value.

## Material inputs

The sole material inputs are the configured C.9 artifacts:

- `artifacts.analysis_weekly_national`;
- `artifacts.analysis_province_summary`;
- `artifacts.analysis_weekly_province`; and
- `artifacts.analysis_age_group_summary`.

The producer also reads `directories.processed_data`, `directories.figures`,
the four configured figure paths, and `visualization.png_resolution_dpi` from
`config/project.yml`. All paths must be project-relative. C.9 inputs must be
inside the configured processed-data directory; outputs must be distinct and
inside the configured figures directory.

Before rendering, each input must satisfy its exact
`analysis_table_derivation` v1.0.0 schema, logical-key, type, schema-version,
and ordering invariants. All four tables must identify the same single scope,
resource, and source year. Their published-row and published-count totals must
reconcile exactly. The producer does not require fixed row counts or totals;
those are properties of the current inputs, not general rules.

## Common semantic and rendering invariants

- The current scope must be `primary_dengue_2024`, the source year 2024, and
  the event semantics are inherited from C.9; these current values are checked
  as regression evidence, not used to substitute or transform input values.
- Every number shown is formatted as an integer using a period as the thousands
  separator and a comma as the decimal separator where a decimal is shown.
- All charts use the same sober visual theme, a system-independent generic
  sans-serif family, zero-based count axes, Spanish text, deterministic order,
  and no randomness.
- `published_row_count` is validated for reconciliation but not encoded as a
  primary visual variable.
- PNG rendering uses the base R `png()` device with `type = "cairo"` and the
  configured 150 dpi. The rendering environment used by the project is
  documented by `renv`; no manually installed font is required.

Identical input data, configuration, package versions, device, and execution
environment must produce identical logical figure content. Byte identity is
tested in the current environment but is not promised across platforms because
the graphics stack can differ.

## Figure artifacts

| Artifact configuration key | Output | Dimensions | Question and representation |
| --- | --- | --- | --- |
| `artifacts.dengue_2024_weekly_national_figure` | `figures/dengue_2024_weekly_national.png` | 2400 x 1350 px | National weekly line of `source_week` and `published_case_count`; all observed W01--W52 are shown, with the maximum annotated. |
| `artifacts.dengue_2024_province_ranking_figure` | `figures/dengue_2024_province_ranking.png` | 2400 x 1800 px | Descending horizontal-bar ranking of known provincial categories only. Ties are broken by `province_id`, then `province_name`. |
| `artifacts.dengue_2024_top5_provinces_weekly_figure` | `figures/dengue_2024_top5_provinces_weekly.png` | 2400 x 1800 px | Fixed-scale small multiples for the five highest-count known provincial categories, selected from the provincial summary with the same deterministic tie-break. |
| `artifacts.dengue_2024_age_group_composition_figure` | `figures/dengue_2024_age_group_composition.png` | 2400 x 1800 px | Horizontal bars for source age-group categories in validated numeric source-ID order; labels remain literal source text. |

The national weekly maximum is identified deterministically by descending
`published_case_count`, then ascending `source_week`. Each top-province peak
uses the same rule within its province. The line in a provincial facet connects
only adjacent observed weeks. A missing point is displayed as absent
publication, never as a zero-valued observation.

The provincial ranking excludes `province_id = "99"` from bars. If that
published category is present, it is communicated separately in the caption as
unknown provincial geography, with its count and share of the full national
denominator; it is never presented as a province. `Sin Especificar` remains a
visible source-age category and is styled as such, not removed. Labels such as
`dÍas` are retained without correction.

## Figure communication requirements

Each figure has a short Spanish title, clear axes, and a concise subtitle or
caption that makes its published-count semantics clear without embedding a
long methodological paragraph. The accompanying README or future report,
rather than image metadata, is the canonical location for extended captions,
source provenance, assumptions, and limitations.

The intended headlines are:

1. weekly national: concentration in the first half of the year, with a W12
   maximum;
2. province ranking: Buenos Aires, Córdoba, and Tucumán concentrate the
   largest published-count share;
3. top-province dynamics: current provincial peaks occur between W12 and W14,
   with Córdoba at W14; and
4. age composition: the three source categories from 25 to 65 years contain a
   majority of published counts.

These are descriptions of the selected published data, not epidemiological
mechanisms, population-adjusted measures, or causal claims.

## Publication and version control

The producer validates all inputs and constructs all plots before rendering.
It renders each full PNG to a project-owned temporary file in the configured
figures directory, then atomically renames it to its final path. Publication is
atomic per figure, not a multi-file transaction. Controlled temporary graphics
are removed on controlled failure.

Unlike regenerable intermediate CSVs, exactly these four final PNGs are curated
portfolio deliverables and are versioned in Git. Their producer, contract, and
configuration are versioned as well. Exploratory graphics and temporary files
are not deliverables and must not be committed.

## Blocking errors

Execution aborts before publication for malformed configuration or paths;
missing or schema-incompatible inputs; failed C.9 key, type, ordering, share,
or reconciliation invariants; disagreement in common scope provenance;
ambiguous province or age-group mappings; no known province for the ranking;
an invalid graphics device or output write; or failed atomic publication.
