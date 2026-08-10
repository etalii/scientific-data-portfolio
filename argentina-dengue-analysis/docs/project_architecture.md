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
03_merge_raw_files.R
    │
    ▼
data/processed/
    │
    ▼
Exploratory Analysis
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
    cleaning/
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
resources are epidemiologically canonical. A later canonicalization stage will
make that selection explicitly before merging.
Its contract is defined in `docs/validation_snapshot_contract.md`.

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

* automatic data validation;
* spatial analysis using sf;
* epidemiological modelling;
* interactive dashboards;
* automated report generation.
