---
name: population-adjusted-rate-analysis
description: Build or audit descriptive population-adjusted indicators when a count-like numerator must be paired with an authoritative denominator, geographic mapping, temporal basis, and sensitivity policy. Do not use when denominator semantics or geographic eligibility are unknown, or when a simple count is the requested output.
---

# Population-adjusted rate analysis

## Goal

Create interpretable, reproducible population-adjusted indicators without
turning a published count into incidence, risk, prevalence, or a person-level
measure by assumption.

## Define the indicator before calculation

Write down:

- numerator semantics, row grain, event scope, and whether it is a count of
  records, events, people, or something else;
- population universe, source authority, reference date, vintage, sex/age scope,
  and geographic grain of the denominator;
- temporal basis of the numerator and denominator, including whether observed
  weeks constitute a complete configured interval;
- scale factor, scenario labels, output units, and terms that are prohibited by
  the numerator semantics.

If the numerator is published surveillance counts without person-level
deduplication or full ascertainment, label the result as a published-count rate
or an equally precise descriptive term, not incidence or individual risk.

## Validate inputs and eligibility

1. Require a documented, authoritative denominator source and retain its
   provenance and checksum where appropriate.
2. Validate denominator coverage, uniqueness, positive finite values, reference
   dates, and configured vintages before joining.
3. Use only validated geographic mappings. Keep exact, name-based, ambiguous,
   unknown, and unmapped categories distinct; do not redistribute excluded
   numerators.
4. Reconcile eligible numerators to the source aggregate and report excluded or
   unassigned amounts separately.
5. For an aggregate region, derive a denominator from the same eligible
   component geography and preserve the rule for partial or absent observations.

## Calculate and publish

- Use an explicit formula and deterministic rounding/display policy.
- Carry scope, denominator scenario, vintage, reference date, geographic
  eligibility, and period-basis metadata with every output.
- When more than one defensible denominator vintage or scenario exists, publish
  separate scenarios and compare them as sensitivity evidence rather than
  selecting one silently.
- Validate output keys, non-negative finite rates, reconciliation, ranking/tie
  rules, and schema before atomic publication.

## Stop conditions

Do not calculate or label a rate as analytically valid when the denominator is
unjustified, the numerator and denominator geography differ, the temporal basis
is unclear, mappings are ambiguous, or the required sensitivity policy has not
been chosen.

## Deliverable

Report the formula, numerator semantics, denominator provenance, eligibility and
exclusions, period basis, scenarios, reconciliations, and interpretation limits.
