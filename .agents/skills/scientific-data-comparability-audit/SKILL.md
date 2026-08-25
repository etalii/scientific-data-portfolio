---
name: scientific-data-comparability-audit
description: Assess whether comparisons across periods, source releases, locations, or populations are analytically supported in a scientific dataset. Use when coverage, schema drift, source semantics, missingness, geography, or denominator changes may affect interpretation. Do not use for a simple summary within one already-certified scope.
---

# Scientific data comparability audit

## Goal

Classify a proposed comparison from evidence rather than assuming that matching
column names, years, or labels imply equivalent measurements.

## Establish the comparison unit

1. State the numerator or measurement represented by one row and by the proposed
   aggregate.
2. Define the periods, sources, geographic grain, population, event definition,
   and observation process being compared.
3. Separate a descriptive comparison from a causal, trend, incidence, risk, or
   prevalence claim. Do not upgrade the claim beyond the input semantics.

## Audit evidence

Inspect contracts, source documentation, provenance, schemas, and quality
snapshots. Evaluate at least:

- temporal coverage and whether observed absence can mean missing rather than
  zero;
- schema and coding changes, including text encoding and category drift;
- row grain, aggregation, duplication, and conflict evidence;
- source or event semantics and changes in surveillance, measurement, or
  classification processes;
- geographic identity, mapping completeness, and unknown/unmapped categories;
- denominator vintage, reference date, and geographic compatibility when rates
  are involved;
- whether each period has comparable observation and publication conditions.

Retain evidence rather than repairing it. A structural mismatch or a quality
finding is not permission to silently harmonize, recode, redistribute, or
zero-fill observations.

## Decision

Use a controlled conclusion such as:

- `supported`: relevant dimensions and evidence are compatible;
- `supported_with_caveats`: comparison is usable only with stated limits;
- `unsupported`: a material semantic, coverage, mapping, or denominator problem
  invalidates the intended comparison;
- `pending_reference_data`: the conclusion requires a missing authoritative
  source or mapping.

Record reason codes and the exact scope of the conclusion. A result can support
one descriptive comparison while leaving a stronger trend or causal claim
unsupported.

## Stop conditions

Stop before publishing a positive conclusion when source semantics are unknown,
coverage cannot be established, geography is ambiguous, a denominator is not
justified, or a source change makes the comparison unit indeterminate.

## Deliverable

Provide a compact evidence table, status per comparison unit, caveats, and a
list of independent information required to upgrade an unsupported conclusion.
