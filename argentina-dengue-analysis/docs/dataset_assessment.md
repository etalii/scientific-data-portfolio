# Argentina dengue analysis

## Dataset assessment

---

**Version:** 0.1

**Status:** draft

**Last Updated:** June 2026

---

# Purpose

This document evaluates the suitability of the selected dataset for answering the research question defined in the Analysis Protocol.

Rather than providing a simple dataset description, this assessment identifies the dataset's strengths, limitations, potential biases and overall fitness for the objectives of this project.

---

# Research question

> **How has dengue surveillance evolved across Argentina since 2018, and what spatial and temporal patterns emerge from official epidemiological data?**

---

# Dataset identification

**Dataset**

Vigilancia de las enfermedades por virus del Dengue y Zika

**Publisher**

Ministry of Health of Argentina

**Portal**

Datos Argentina – Open Data Portal

**URL**

https://datos.gob.ar/dataset/salud-vigilancia-enfermedades-por-virus-dengue-zika

**Format**

CSV

**Geographic coverage**

Argentina

**Temporal coverage**

2018 – 2025

**Update frequency**

Weekly

**License**

Open Government Data.

---

# Why this dataset?

The selected dataset satisfies several important criteria for this project.

* It is an official government data source.
* It contains national epidemiological surveillance information.
* It provides temporal information through epidemiological weeks.
* It includes geographic information at the provincial level.
* It is openly accessible.
* It can be downloaded without registration.
* It is regularly updated.

These characteristics make it suitable for building a reproducible analytical workflow.

---

# Expected variables

Based on the official documentation, the dataset is expected to contain variables such as:

* epidemiological year
* epidemiological week
* province
* localidad/ partido/ comuna
* disease
* age
* reported cases

The final variable list will be confirmed after data acquisition.

---

# Strengths

The dataset offers several advantages.

* Official public source.
* National geographic coverage.
* Standardized epidemiological reporting.
* Longitudinal observations.
* Suitable for temporal analyses.
* Suitable for spatial comparisons.
* Appropriate for reproducible workflows.

---

# Potential limitations

Several limitations should be considered before interpreting analytical results.

* Surveillance data may underestimate true incidence.
* Reporting delays may occur.
* Surveillance protocols may change over time.
* Data are aggregated rather than individual-level.
* Environmental variables are not included.
* Population size is not directly incorporated.

These limitations do not invalidate the analysis but should be acknowledged throughout the project.

---

# Potential sources of bias

Possible biases include:

* underreporting
* changes in surveillance intensity
* diagnostic availability
* regional differences in reporting
* temporal inconsistencies

These factors should be considered when interpreting observed patterns.

---

# Suitability for the research question

The dataset is considered highly appropriate for answering the project's primary research question.

It enables:

* temporal trend analysis
* seasonal exploration
* province-level comparisons
* descriptive epidemiology
* exploratory statistical analysis
* reproducible data visualization

However, it is not appropriate for:

* causal inference
* predictive modelling
* estimating infection risk
* evaluating environmental drivers without additional datasets

---

# Additional data required

Future versions of the project may incorporate:

* provincial population estimates
* climate variables
* geographic boundaries
* socioeconomic indicators

These complementary datasets would enable more advanced analyses.

---

# Data quality checklist

| Item                          | Status |
| ----------------------------- | ------ |
| Official source identified    | ✅      |
| Public access                 | ✅      |
| Download URL available        | ✅      |
| Metadata available            | ☐      |
| Variable dictionary reviewed  | ☐      |
| License verified              | ✅      |
| File integrity verified       | ☐      |
| Initial exploration completed | ☐      |

---

# Assessment conclusion

The selected dataset provides an appropriate foundation for a reproducible exploratory analysis of dengue surveillance in Argentina.

Although the dataset presents expected limitations inherent to surveillance systems, its official origin, national coverage and standardized reporting structure make it well suited for the objectives of this project.

The next phase will focus on automated data acquisition, validation and documentation prior to exploratory analysis.
