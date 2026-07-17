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

↓

Download

01_download_data.R

↓

Validation

02_validate_downloads.R

↓

Merge

03_merge_raw_files.R

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