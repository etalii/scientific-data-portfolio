# Argentina dengue analysis

*A reproducible data analysis workflow for exploring dengue surveillance in Argentina.*

---

## Project overview

This repository presents a reproducible workflow for the exploratory analysis of official dengue surveillance data from Argentina.

The project combines scientific research practices with modern Data Analytics tools to investigate temporal and spatial patterns of dengue notifications using publicly available epidemiological records.

Rather than focusing exclusively on epidemiological findings, this repository emphasizes transparent methodology, reproducible analyses and effective communication of results.

---

## Why this project?

Scientific research and data analytics share the same fundamental objective:

> Transform raw data into reliable evidence that supports informed decisions.

As a biologist with experience in disease ecology and quantitative research, I developed this project to demonstrate how scientific analytical workflows can be applied to modern data analysis.

The repository showcases not only statistical results, but also the complete analytical process behind them.

---

## Research question

> **How has dengue surveillance evolved across Argentina since 2018, and what spatial and temporal patterns emerge from official epidemiological data?**

---

## Objectives

The project aims to:

* Build a fully reproducible analytical workflow.
* Explore temporal dynamics of dengue surveillance.
* Characterize seasonal epidemiological patterns.
* Compare dengue activity among Argentine provinces.
* Produce publication-quality visualizations.
* Document every analytical decision transparently.

---

## Dataset

**Source**

Official Argentine Health minister´s open data portal (datos.org.ar)

Dataset:

**Vigilancia de las enfermedades por virus del Dengue y Zika**

Current project version focuses exclusively on dengue notifications.

A detailed evaluation of dataset quality is available in:

```text
docs/dataset_assessment.md
```

---

## Workflow

The project follows a reproducible analytical pipeline.

```text
Research Question
        │
        ▼
Dataset Acquisition
        │
        ▼
Data Validation
        │
        ▼
Data Cleaning
        │
        ▼
Exploratory Data Analysis
        │
        ▼
Statistical Analysis
        │
        ▼
Visualization
        │
        ▼
Interpretation
        │
        ▼
Quarto Report
```

Each stage is implemented independently to maximize transparency and reproducibility.

---

## Repository Structure

```text
argentina-dengue-analysis/

├── README.md
├── LICENSE
├── .gitignore
│
├── docs/
│   ├── analysis_protocol.md
│   ├── dataset_assessment.md
│   └── project_log.md
│
├── data/
│   ├── raw/
│   ├── processed/
│   └── metadata/
│
├── scripts/
├── reports/
├── figures/
├── outputs/
└── references/
```

---

## Technologies

### Programming

* R
* SQL (planned)

### Data Analysis

* tidyverse
* ggplot2
* janitor
* lubridate
* sf *(planned)*

### Tools

* Quarto
* Visual Studio Code

---

## Reproducibility

This project follows reproducible research principles.

* Raw datasets are never modified manually.
* Every transformation is generated through code.
* Every figure is reproducible.
* Analytical decisions are documented.
* The complete workflow can be reproduced from this repository.

---

## Project status

**Current stage**

🟢 Planning

Completed:

* Project definition
* Analysis protocol
* Repository organization

Next milestones:

* Dataset assessment
* Data acquisition
* Data cleaning
* Exploratory data analysis
* Statistical analysis
* Quarto report

---

## Documentation

The repository contains complementary documentation describing the project.

| Document                     | Purpose                                      |
| ---------------------------- | -------------------------------------------- |
| `README.md`                  | General project overview                     |
| `docs/analysis_protocol.md`  | Analytical methodology                       |
| `docs/dataset_assessment.md` | Dataset evaluation                           |
| `docs/project_log.md`        | Chronological record of analytical decisions |

---

## Long-term vision

This repository is intended to become a complete reproducible case study in scientific data analysis.

Future versions may include:

* Climate variables
* Population-adjusted incidence
* Spatial statistical models
* Interactive dashboards
* Automated data acquisition
* Comparison with additional arboviruses

---

## About the author

**Andrés Lemos**

Biologist (University of Buenos Aires)

Scientific research • Data Analysis • R • Python • SQL

Interested in:

* Disease ecology
* Epidemiology
* Environmental data
* Scientific computing
* AI evaluation

---

> *Good data analysis is not only about obtaining results—it is about building transparent and reproducible evidence.*
