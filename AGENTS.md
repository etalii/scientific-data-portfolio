# AGENTS.md

## Repository Purpose

This repository contains reproducible scientific data analysis projects.

The first project is:

- argentina-dengue-analysis

The objective is to build a fully reproducible epidemiological data pipeline in R.

---

## General Principles

Always preserve raw data.

Never overwrite original files.

Prefer reproducible scripts over manual operations.

Every transformation must be documented.

Every script should perform a single responsibility.

Prefer explicit code over clever code.

---

## Programming Language

Primary language:

- R

Follow tidyverse style.

---

## Project Structure

data/raw/

Immutable datasets.

data/processed/

Derived datasets.

data/metadata/

Metadata and logs.

scripts/

Analysis pipeline.

docs/

Project documentation.

reports/

Generated reports.

---

## Coding Style

Use snake_case.

Use descriptive variable names.

Comment only when necessary.

Functions should be short.

Avoid duplicated code.

---

## Documentation

Every new script begins with a descriptive header.

Every function has documentation.

---

## Git Workflow

Small commits.

Meaningful commit messages.

Never commit generated data.

Never commit temporary files.

---

## Scientific Principles

Reproducibility first.

Transparency first.

Document every assumption.

Preserve provenance.

---

## Communication

Documentation is written in English.

Discussions with the user are in Spanish.