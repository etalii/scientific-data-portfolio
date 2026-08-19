# Project architecture

## Purpose

This document describes the architecture of the *Argentina Dengue Analysis* project, including its directory organization, data pipeline, configuration strategy, and reproducibility principles.

The objective is to ensure that every stage of the analysis is transparent, modular, and reproducible.

---

# Project goals

The project aims to:

* build a fully reproducible data analysis workflow;
* automatically retrieve official dengue surveillance datasets from Argentina;
* validate and organize raw data;
* generate processed datasets ready for analysis;
* produce statistical analyses and visualizations suitable for scientific communication.

---

# High-level architecture

```
CKAN API
    │
    ▼
00_fetch_metadata.R
    │
    ▼
resources_catalog.csv
    │
    ▼
01_download_data.R
    │
    ▼
data/raw/
    │
    ▼
02_validate_downloads.R
    │
    ▼
validation_snapshot.csv
    │
    ▼
03_select_canonical_resources.R
    │
    ▼
canonical_resources.csv
    │
    ▼
04_harmonize_canonical_resources.R
    │
    ▼
canonical_resources_structural.csv
    │
    ▼
05_assess_harmonized_quality.R
    │
    ▼
harmonized_quality_snapshot.csv
    │
    ▼
06_select_analysis_scope.R
    │
    ▼
primary_dengue_analysis_rows.csv
    │
    ▼
07_build_analysis_tables.R
    │
    ▼
analysis_weekly_national.csv
analysis_province_summary.csv
analysis_weekly_province.csv
analysis_age_group_summary.csv
    │
    ▼
08_generate_figures.R
    │
    ▼
Four curated descriptive portfolio figures
    │
    ▼
Reports and Figures
```

Each script has a single responsibility, following a modular pipeline design.

The catalog is a versioned internal contract. Its schema, data types, source
mapping and download-eligibility policy are defined in
`docs/resources_catalog_contract.md`.

---

# Directory structure

```
config/
data/
docs/
figures/
outputs/
references/
reports/
scripts/
    acquisition/
    validation/
    processing/
    analysis/
    visualization/
    utils/
```

Each directory has a clearly defined purpose to improve maintainability and reproducibility.

---

# Configuration management

All project configuration is centralized in:

```
config/project.yml
```

This file stores project parameters only.

Dataset metadata are never hardcoded and are always retrieved from the CKAN API.

For metadata acquisition, the configuration defines the CKAN package endpoint,
the dataset identifier, the resource-selection criteria and the path of the
catalog artifact. Scripts must not hardcode those values.

---

# Metadata management

Metadata retrieval is performed automatically.

The metadata catalog is stored as:

```
data/metadata/resources_catalog.csv
```

This file serves as the input for the download pipeline.

The catalog is an internal, generated artifact rather than a copy of the CKAN
response. It records every discovered resource and explicitly identifies the
resources selected for download. The contract is versioned independently so
schema changes can be managed explicitly.

The catalog is versioned as provenance metadata. The append-only operational
download log is defined separately in `docs/download_log_contract.md` and is
excluded from Git.

Acquisition and validation are mutually exclusive per workspace. A configured,
Git-ignored acquisition-validation lock directory in `data/metadata/` is
acquired atomically before either stage observes or changes raw-data state and
associated metadata. The acquisition stage also uses external staging, a verified hidden
publication temporary inside `data/raw/` when required for atomic publication,
and an atomically updated operational log.

Validation produces `data/metadata/validation_snapshot.csv`, a current-state
snapshot rather than a historical event log. It reports physical integrity,
provenance and basic readability without deciding which technically valid
resources are epidemiologically canonical. Canonicalization subsequently makes
that selection explicitly at resource level.
Its contract is defined in `docs/validation_snapshot_contract.md`.

Canonical resource selection consumes only technically processable validation
records and calculates exact temporal coverage from explicitly configured
column pairs. It publishes `data/metadata/canonical_resources.csv`, a stable,
Git-versioned analytical-provenance manifest. The stage selects one resource
per equivalent coverage group using a documented editorial precedence rule;
it does not merge, clean, filter, harmonize, or deduplicate observations. Its
contract is defined in `docs/canonical_resource_selection_contract.md`.

Structural harmonization reads the canonical manifest, the validation snapshot
for its previously validated delimiters, and the immutable raw resources. It
creates one deterministic structural row per source CSV record while preserving
source IDs, source text and source-row provenance. It deliberately does not
assert epidemiological comparability of time, count, geography or age-group
fields across source-schema families. Its contract is defined in
`docs/structural_harmonization_contract.md`.

Harmonized-quality assessment reads the structural artifact and publishes a
deterministic, Git-ignored metadata snapshot of reproducible quality findings.
It is an assessment stage, not a cleaning or consolidation stage: it never
changes rows, values, counts, source provenance, or raw files. Its contract is
defined in `docs/harmonized_quality_assessment_contract.md`.

Analysis-scope selection reads the structural artifact and explicit scope
criteria from the project configuration. It publishes a deterministic,
row-preserving analytical subset. It does not consume quality findings to
alter selection, deduplicate records, or aggregate counts; quality assessment
remains a separate source of evidence for subsequent analytical decisions. Its
contract is defined in `docs/analysis_scope_selection_contract.md`.

Analysis-table derivation reads only the selected primary scope and builds four
deterministic aggregations of published rows and published counts: national
weekly, provincial, provincial-weekly, and source-age-group summaries. It does
not resolve quality findings, deduplicate observations, or infer individual
cases. Its contract is defined in `docs/analysis_table_derivation_contract.md`.

Descriptive visualization reads only those four C.9 tables and publishes four
curated PNG portfolio figures. It preserves their published-count semantics and
does not read raw data, repair quality findings, complete absent observations,
or make epidemiological inferences. Its contract is defined in
`docs/portfolio_descriptive_visualization_contract.md`.

---

# Data management

Raw datasets remain immutable.

```
data/raw/
```

The raw-data directory must never expose an incomplete or unverified file under
its final catalog filename. Downloads are staged outside this directory. When
an atomic cross-directory move is unavailable, the acquisition stage may use a
hidden, project-owned publication temporary inside `data/raw/`, verify it, and
atomically rename it to the final filename. These temporaries are not raw data
and are excluded from every downstream stage.

Processed datasets are generated separately.

```
data/processed/
```

Regenerable intermediate data and metadata snapshots are ignored by Git. The
four final C.10 portfolio figures in `figures/` are a deliberate exception:
they are versioned deliverables and must be reproducible from their versioned
producer, configuration, and C.9 inputs. Exploratory graphics and controlled
temporary graphics are not deliverables and must not be committed.

Logs documenting downloads and validation are stored in:

```
data/metadata/
```

---

# Reproducibility

The project uses:

* Git for version control;
* renv for package management;
* YAML configuration files;
* modular R scripts;
* Quarto reports.

No manual modification of downloaded datasets is allowed.

---

# Future extensions

Future versions of the project will include:

* spatial analysis using sf;
* epidemiological modelling;
* interactive dashboards;
* a policy-controlled narrative report.
