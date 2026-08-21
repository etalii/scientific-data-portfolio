# AI Context

## Project

Argentina Dengue Analysis

---

## Repository

scientific-data-portfolio

---

## Purpose

Build a fully reproducible scientific workflow for analysing dengue surveillance data in Argentina using official public datasets.

---

## Core principles

- reproducibility
- transparency
- modularity
- documentation-first
- version control
- automation whenever possible

---

## Data source

Official datasets published through datos.gob.ar.

Dataset metadata must always be retrieved automatically from the CKAN API.

No resource URLs should be hardcoded.

---

## Project architecture

Configuration

config/project.yml

↓

Metadata retrieval

00_fetch_metadata.R

↓

Resource catalogue

resources_catalog.csv

Contract: resources_catalog v2.0.0

↓

Download

01_download_data.R

↓

Operational log

download_log.csv (download_log v1.0.0)

↓

Validation

02_validate_downloads.R

↓

Validation snapshot

validation_snapshot.csv (validation_snapshot v1.0.0)

↓

Canonical resource selection

03_select_canonical_resources.R

↓

canonical_resources.csv (canonical_resource_selection v1.0.0)

↓

Structural harmonization

04_harmonize_canonical_resources.R

↓

canonical_resources_structural.csv (structural_harmonization v1.0.0)

↓

Harmonized quality assessment

05_assess_harmonized_quality.R

↓

harmonized_quality_snapshot.csv (harmonized_quality_assessment v1.0.0)

↓

Analysis scope selection

06_select_analysis_scope.R

↓

primary_dengue_analysis_rows.csv (analysis_scope_selection v1.0.0)

↓

Analysis-table derivation

07_build_analysis_tables.R

↓

analysis_weekly_national.csv
analysis_province_summary.csv
analysis_weekly_province.csv
analysis_age_group_summary.csv
(analysis_table_derivation v1.0.0)

↓

Descriptive portfolio visualization

08_generate_figures.R

↓

dengue_2024_weekly_national.png
dengue_2024_province_ranking.png
dengue_2024_top5_provinces_weekly.png
dengue_2024_age_group_composition.png
(portfolio_descriptive_visualization v1.0.0)

data/processed

---

## Data policy

Never modify raw files.

Never overwrite official datasets.

Every execution must produce logs.

The four final figures are versioned portfolio deliverables. Regenerable
intermediate data and operational metadata remain ignored by Git.

The v1.1 multiyear extension adds row-preserving Dengue scopes, descriptive
tables, a versioned comparability snapshot, and an independent C.14 population
reference acquisition stage. C.14 reads official INDEC C1 workbooks, preserves
their immutable raw bytes, versions source provenance, and creates a
regenerable normalized denominator reference. It does not calculate rates,
seasons, models, Quarto, or Power BI artifacts.

C.15 derives the INDEC provincial reference from C.14, records source-to-
reference and reference-to-BEN-region crosswalks, and measures geographic
mapping completeness. It preserves source geography and does not calculate
rates.

C.16 publishes descriptive published-count rates by combining C.12 aggregates
with C.14 denominators and C.15 eligibility evidence. It does not claim
incidence and does not reaggregate C.11 or read raw datasets.

C.17 is a row-preserving, configured source-week selection from C.11 for the
SE31/2024--SE30/2025 season window. It validates exact tuple coverage and
preserves annual-scope lineage, but does not calculate seasonal rates.

C.20 is an additive presentation stage. It produces four versioned PNGs from
certified C.16, C.18, and C.19 artifacts, keeping season and calendar-year
scopes explicitly separate. It does not read raw data, rebuild aggregates,
calculate rates, model, or generate reports or dashboards.

---

## Coding standards

- tidyverse style
- snake_case
- one responsibility per script
- English comments
- explicit documentation

---

## Goal

The entire project should be reproducible by cloning the repository and executing the pipeline.
