# Argentina dengue analysis

**Analysis protocol**

---

**Version:** 0.1

**Status:** planning

**Author:** Andrés Lemos

**Last updated:** june 2026

---

# 1. Project overview

## Project title

**Argentina dengue analysis: a reproducible workflow for the exploratory analysis of national dengue surveillance data**

## Project description

This project aims to develop a fully reproducible analytical workflow to explore the temporal and spatial dynamics of dengue surveillance in Argentina using official epidemiological data published through the argentine open data portal "Datos Argentina".

The project is designed as both a scientific data analysis case study and a professional Data Analytics portfolio project. Rather than focusing exclusively on epidemiological findings, it emphasizes reproducibility, transparent methodology, and effective communication of analytical results.

---

# 2. Background

Dengue is one of the fastest-growing arborne diseases worldwide and has become an increasingly important public health concern in Argentina over the past decade.

The availability of official surveillance data provides an opportunity to explore temporal trends, geographic variation, and epidemiological patterns through reproducible analytical workflows.

Beyond its public health relevance, this project demonstrates how scientific research practices can be integrated into modern data analytics by combining statistical analysis, reproducible programming, version control, and clear documentation.

---

# 3. Research question

**Primary question**

> How has dengue surveillance evolved across Argentina since 2018, and what spatial and temporal patterns emerge from official epidemiological data?

---

# 4. Objectives

## General objective

To build a reproducible data analysis workflow that explores dengue surveillance patterns in Argentina using official open data.

## Specific Objectives

* Import and document official surveillance datasets.
* Clean and standardize epidemiological records.
* Explore temporal trends in dengue notifications.
* Identify seasonal patterns across epidemiological weeks.
* Compare dengue activity among Argentine provinces.
* Produce high-quality statistical visualizations.
* Generate a fully reproducible analytical report.

---

# 5. Project scope

## Included

* Official epidemiological surveillance data
* Data import and validation
* Data cleaning
* Exploratory data analysis (EDA)
* Descriptive statistics
* Temporal analysis
* Spatial visualization
* Reproducible reporting
* Version control using Git

## Excluded

* Predictive modelling
* Machine Learning
* Causal inference
* Climate-driven modelling
* Individual-level epidemiological analysis
* Real-time surveillance

These topics may be incorporated into future versions of the project.

---

# 6. Dataset

## Data source

Official Argentine Open Data Portal: Datos Argentina (datos.org.ar)

Dataset: "Vigilancia de las enfermedades por virus del Dengue y Zika"

**Surveillance of dengue and zika virus diseases**

## Expected coverage

* Argentina
* Weekly epidemiological reports
* Provincial level
* Beginning in 2018

## Data characteristics

Expected variables include:

* Epidemiological week
* Year
* Province
* Disease
* Number of reported cases

A complete evaluation of dataset quality will be documented separately in **docs/dataset_assessment.md**.

---

# 7. Analytical strategy

The project will follow a sequential and fully reproducible workflow.

```
Research question
        │
        ▼
Dataset acquisition
        │
        ▼
Data validation
        │
        ▼
Data import
        │
        ▼
Data cleaning
        │
        ▼
Exploratory data analysis
        │
        ▼
Descriptive statistics
        │
        ▼
Visualization
        │
        ▼
Interpretation
        │
        ▼
Reproducible report
```

Each stage will be implemented through independent scripts to maximize transparency and reproducibility.

---

# 8. Statistical approach

The project focuses primarily on descriptive and exploratory analyses.

Planned methods include:

* Summary statistics
* Frequency distributions
* Time series visualization
* Seasonal trend analysis
* Province-level comparisons
* Distribution analysis
* Correlation analysis (if appropriate)

The selection of statistical methods may evolve after the initial exploration of the dataset.

---

# 9. Software and technologies

## Programming languages

* R
* SQL (future integration)

## R packages

* tidyverse
* janitor
* lubridate
* ggplot2
* sf (planned)

## Tools

* Git
* GitHub
* Quarto
* Visual Studio Code

---

# 10. Expected outputs

The final repository will contain:

* Cleaned datasets
* Reproducible R scripts
* Statistical tables
* Publication-quality figures
* Quarto report
* Complete project documentation
* Version-controlled analytical workflow

---

# 11. Reproducibility plan

The project follows reproducible research principles.

Specifically:

* Raw datasets will never be modified manually.
* Every transformation will be scripted.
* Every figure will be generated automatically.
* All analytical decisions will be documented.
* The complete analysis will be executable from the repository.

---

# 12. Data management plan

The project follows a structured data management strategy to ensure traceability, reproducibility, and long-term maintainability.

## Directory structure

Raw data will be stored in:

`data/raw/`

Processed datasets generated by analysis scripts will be stored in:

`data/processed/`

Metadata describing data sources, variables and download information will be stored in:

`data/metadata/`

## Data integrity

- Raw data will remain unchanged after download.
- Every processed dataset will be generated through scripted workflows.
- No manual editing of datasets will be performed.
- Intermediate datasets will be clearly documented.

## File naming convention

Files will follow descriptive, lowercase names using underscores.

Examples:

- dengue_cases_2018.csv
- dengue_cleaned.csv
- province_summary.csv

## Version control

Only analysis code, documentation and lightweight processed datasets will be tracked with Git.

Large raw datasets may be excluded through `.gitignore` when appropriate.

## Documentation

All data transformations will be documented within analysis scripts and recorded in the project log whenever major analytical decisions are made.

---

# 13. Quality criteria

The project will be considered complete when:

* All scripts execute without errors.
* Figures are generated automatically.
* Documentation is complete.
* Results are reproducible.
* Repository organization is clear.
* The Quarto report can be rendered successfully.
* All Git commits are documented.

---

# 14. Known limitations

Potential limitations include:

* Aggregated surveillance data
* Possible underreporting
* Reporting delays
* Changes in surveillance practices
* Limited environmental covariates
* No individual-level observations

These limitations will be acknowledged throughout the analysis.

---

# 15. Future extensions

Possible future developments include:

* Integration of climate variables
* Population-adjusted incidence calculations
* Spatial statistical models
* Interactive dashboards
* Comparison with other arboviruses
* Automated data update pipeline

---

# 16. Project philosophy

This project is based on the idea that scientific research and modern data analytics share the same fundamental principles:

* rigorous methodology,
* transparent workflows,
* reproducible analyses,
* evidence-based conclusions.

Rather than presenting only analytical results, this repository documents the complete process through which those results are produced.
