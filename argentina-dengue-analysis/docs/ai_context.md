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

Merge

05_merge_raw_files.R

↓

Processed datasets

data/processed

---

## Data policy

Never modify raw files.

Never overwrite official datasets.

Every execution must produce logs.

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
