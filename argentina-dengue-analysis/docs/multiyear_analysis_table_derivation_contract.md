# Multiyear Analysis Table Derivation Contract

## Contract identity

- **Contract ID:** `multiyear_analysis_table_derivation`
- **Version:** `1.0.0`
- **Producer:** `scripts/analysis/12_build_multiyear_analysis_tables.R`

## Inputs and outputs

The sole material input is `multiyear_dengue_scope` v1.0.0. The producer writes
four regenerated CSVs: national weekly, province summary, province-week, and
source-age-group summary.

Every table contains `multiyear_analysis_table_schema_version`,
`analysis_scope_id`, `source_resource_id`, and `source_year`. It aggregates
published rows and published counts only.

## Semantics

- National weekly rows exist only for observed source weeks.
- Provincial tables group by the source pair `(province_id, province_name)`;
  multiple names for one ID remain distinct published categories.
- Provincial shares use the full scope published-count total, including any
  source category of unknown geography.
- Age summaries group by `(source_age_group_id, source_age_group_label)` for
  every year. They do not infer common age categories or abort on a source
  ID-to-label conflict.

The current `dengue_2018` regression expectation is 17 source ID/label pairs.
The complete 2018 resource has 29 pairs, but 12 belong only to non-Dengue
events and are intentionally outside this contract.
- The stage neither reads quality findings nor corrects, filters, imputes,
  deduplicates, or recodes values.

All outputs are regenerable processed data and ignored by Git.
