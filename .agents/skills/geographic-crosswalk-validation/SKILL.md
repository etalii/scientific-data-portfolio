---
name: geographic-crosswalk-validation
description: Build or audit an explicit crosswalk from source geographic categories to a documented reference geography, including mapping completeness and ambiguity handling. Use before geographic aggregation, comparison, or rate construction. Do not use for generic text cleanup or to invent a mapping from names alone.
---

# Geographic crosswalk validation

## Goal

Make geographic attribution auditable while preserving source values and
preventing ambiguous, unknown, or unmapped records from being silently assigned.

## Inputs and preconditions

Require a source artifact with provenance, source geography fields, and a
documented reference geography. Define the intended geographic grain and any
higher-level aggregation before building mappings.

## Workflow

1. Preserve raw source IDs and names exactly. Create comparison-only forms only
   for a documented, narrow matching rule; never overwrite source values.
2. Prefer documented exact-ID matches. Validate that each reference ID maps to
   one reference name and that IDs retain their required representation.
3. Treat a name-based fallback as a distinct evidence class. It is not equivalent
   to an exact identifier match unless independently validated.
4. Classify every observed source category with controlled statuses, for example
   `documented_exact`, `validated_exact`, `name_based_unverified`, `ambiguous`,
   `unknown_source_category`, or `unmapped`.
5. Build higher-level regions from the reference geography, not by assigning
   unknown source categories directly. Validate one-and-only-one membership for
   each reference unit where the regional scheme requires it.
6. Publish a completeness assessment that keeps mapped, name-based, ambiguous,
   unmapped, and unknown records separate. State whether the intended analysis
   is supported, supported with caveats, or unsupported.

## Invariants

- Never pad, reformat, transliterate, or normalize IDs as a final transformation
  without an approved rule and audit trail.
- Never resolve an ambiguity by choosing the most plausible name.
- Never turn unknown or missing geography into a region, zero, or redistributed
  numerator.
- Reconcile mapped totals and exclusions to the scoped source total.

## Stop conditions

Stop before geographic aggregation or rates when the reference authority is
unclear, an ID maps to multiple places, a required source category is ambiguous,
or mapping coverage fails the approved eligibility rule.

## Deliverable

Publish or report the crosswalk, evidence class per source category, reference
provenance, mapping completeness, reconciliation, unresolved categories, and
the exact analyses that remain eligible.
