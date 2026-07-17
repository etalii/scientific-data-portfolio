# AGENTS.md

## Project

Argentina Dengue Analysis

This project is part of the Scientific Data Portfolio repository.

The objective is to build a fully reproducible epidemiological data analysis
pipeline using official Argentine government data.

The project emphasizes:

- reproducibility
- transparency
- modularity
- scientific best practices
- version control
- automation
- documentation

---

# Repository Structure

The project follows this architecture:

```
config/
data/
    raw/
    processed/
    metadata/

scripts/
    acquisition/
    processing/
    analysis/
    visualization/
    utils/

reports/
figures/
outputs/
references/
docs/
```

Each script must have a single responsibility.

---

# Pipeline

The acquisition pipeline is:

```
00_fetch_metadata.R
        ↓
resources_catalog.csv
        ↓
01_download_data.R
        ↓
download_log.csv
        ↓
02_validate_downloads.R
        ↓
validation_log.csv
        ↓
03_merge_raw_files.R
        ↓
processed dataset
```

Scripts should never duplicate responsibilities.

---

# Configuration

Configuration must live only in:

```
config/project.yml
```

Do not hard-code:

- URLs
- paths
- dataset identifiers
- output directories

These values must always come from project.yml.

---

# Data policy

Only official public data may be used.

Preferred source:

https://datos.gob.ar/

Raw files are immutable.

Never edit files inside:

```
data/raw/
```

Any transformation must create a new artifact.

---

# Metadata

Every download must generate metadata.

Metadata include:

- download date
- original URL
- filename
- checksum (future)
- source identifier

Metadata files belong in:

```
data/metadata/
```

---

# Coding Style

Use:

- snake_case
- tidyverse style
- explicit package namespaces whenever useful

Functions should be small.

Avoid long scripts.

Prefer pipes.

Comment only when comments add information.

---

# Reproducibility

The project uses:

- renv
- DESCRIPTION
- Git

Do not introduce dependencies without updating:

```
DESCRIPTION
renv.lock
```

---

# Git

Commit frequently.

Commit messages should use imperative mood.

Examples:

Add metadata retrieval script

Create download validation pipeline

Refactor filename generation

Avoid large commits.

---

# Documentation

Every exported script starts with a header describing:

- purpose
- inputs
- outputs

README.md should always reflect the current project status.

---

# Visualization

Figures should be reproducible.

Never edit figures manually.

All figures must be generated from scripts.

---

# Statistical analyses

Prefer:

- reproducible workflows
- transparent preprocessing
- explicit assumptions

Avoid hidden transformations.

---

# Agent behavior

When proposing changes:

1. preserve reproducibility
2. minimize duplicated code
3. keep scripts modular
4. avoid hard-coded values
5. explain architectural decisions
6. prioritize maintainability over shortcuts

When uncertain, prefer a cleaner architecture instead of a faster implementation.

## Engineering Principles

The assistant should act as a senior software engineer and data engineer, not merely as a code generator.

When evaluating a proposed solution:

- Challenge architectural decisions when appropriate.
- Explain trade-offs before implementation.
- Prefer maintainability, reproducibility and clarity over brevity.
- Suggest improvements when a better design exists.
- Do not implement significant architectural changes without first presenting and discussing the proposed design.
- Treat the repository as a long-term scientific software project rather than a one-off analysis.

When there are multiple valid approaches:

1. Explain the alternatives.
2. Recommend one and justify it.
3. Wait for approval before implementing major architectural changes.