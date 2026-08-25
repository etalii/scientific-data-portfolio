---
name: contract-first-data-pipeline
description: Design, extend, or review a multi-stage scientific data pipeline when artifacts cross stage boundaries and require explicit contracts, provenance, validation, and regression certification. Do not use for a one-off analysis or a local edit that creates no durable hand-off.
---

# Contract-first data pipeline

## Goal

Deliver a new or changed pipeline stage without silently changing upstream
meaning, provenance, or certified outputs.

## Before implementation

1. Read the applicable repository and project instructions, architecture,
   configuration, existing contracts, and generated-file policy.
2. Map the proposed stage as `inputs -> transformation -> output artifact`.
   Identify the owner of every input and output, including operational metadata.
3. Decide whether the task is a new stage, a contract correction, or a local
   implementation fix. Do not expand a local fix into a new pipeline design.
4. Stop and seek direction if input semantics, artifact ownership, overwrite
   policy, or downstream use is unclear.

## Design the contract first

Document the contract before coding. Include only fields and rules with a
consumer or audit purpose:

- contract identifier and version;
- producer, inputs, and output path policy;
- exact schema, column order, types, nullable fields, logical keys, controlled
  vocabularies, and deterministic ordering;
- provenance retained and transformations explicitly excluded;
- invariants, reconciliation checks, error policy, and atomic-publication rule;
- version-control status of the generated artifact.

Keep raw inputs immutable. Treat source APIs and externally published schemas as
unstable interfaces: translate them at the boundary into a project contract
rather than leaking them through the pipeline. Centralize configurable paths,
identifiers, thresholds, and policies; permit only the minimum bootstrap path
needed to locate configuration.

## Implement one stage

- Give the executable one responsibility and keep reusable contract logic in a
  narrowly scoped shared utility only when it has more than one real consumer.
- Validate inputs before constructing outputs. Fail explicitly for incompatible
  schemas, ambiguous identity, invalid configuration, or breached invariants.
- Use a temporary in the destination filesystem and atomic rename for durable
  artifacts when partial publication would be harmful.
- Do not infer missing semantics, silently coerce ambiguous values, overwrite
  immutable data, fill absent observations, or collapse conflicting evidence
  unless the approved contract explicitly authorizes it.

## Validate and certify

1. Test representative valid and invalid inputs or isolated pure functions.
2. Run the stage from the documented project root.
3. Verify exact schema, keys, controlled vocabularies, reconciliation, expected
   artifact location, and cleanup of locks or temporaries.
4. Re-run when idempotence or deterministic publication is a contract property.
5. Hash or otherwise compare closed upstream artifacts before and after the
   change. Report every legitimate change explicitly.
6. Run whitespace and generated-file checks appropriate to the repository.

## Output contract

Report the artifact produced, contract checks performed, inputs left unchanged,
known limitations, and any decision that needs approval before a downstream
stage proceeds.
