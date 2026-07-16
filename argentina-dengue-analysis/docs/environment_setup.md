# Environment Setup

## Purpose

This document describes the software environment required to reproduce the project.

---

# Operating System

Ubuntu 22.04 LTS

---

# R

Required version:

- R >= 4.3

Package management:

- renv

---

# System Dependencies

The following Ubuntu packages are required:

```bash
sudo apt install \
    build-essential \
    pkg-config \
    cmake \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev
```

---

# R Packages

Project packages are managed using:

- renv

To restore the environment:

```r
renv::restore()
```

---

# Environment Verification

The project includes:

```bash
Rscript scripts/utils/check_environment.R```

which verifies:

- project structure
- required packages
- configuration files
- renv installation

and generates an environment report.

---

# Reproducibility

No package should be installed manually without updating:

- renv.lock

The lockfile is the authoritative description of the R environment.
