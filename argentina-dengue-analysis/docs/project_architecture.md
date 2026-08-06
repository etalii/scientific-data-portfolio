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
validation_log.csv
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
mapping and selection policy are defined in
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

---

# Data management

Raw datasets remain immutable.

```
data/raw/
```

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
