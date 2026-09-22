# DataSpec v0.1

**Status: minimum schemas and read-only R validator implemented.** Updated on
2026-09-22. Project adoption pilots remain pending.

DataSpec connects scientific questions, analytical contracts, reproducible
evidence, defensible claims, narrative design, and visual communication through
explicit, versioned relationships. It builds on this repository's existing
contract-first workflows and R/Quarto implementation.

The common implementation validates synthetic artifact bundles, references,
local file hashes, dependency freshness, and recorded review prerequisites.
It does not migrate projects, install external skills, execute analyses, or
certify scientific results. Existing project contracts remain authoritative.

## Run the minimum implementation

From the portfolio root, with R 4.1 or later and the dependencies recorded in
[DESCRIPTION](DESCRIPTION) and [renv.lock](renv.lock):

```bash
Rscript dataspec/validators/validate.R \
  dataspec/tests/fixtures/minimal/bundle.json \
  dataspec/tests/fixtures/minimal

Rscript dataspec/tests/run_tests.R
```

The first command prints a deterministic JSON report to stdout. Exit 0 means
the declared structure and traceability passed; exit 1 means validation failed;
exit 2 means input parsing, invocation, or runtime failed. It writes no files.
`certification` remains `not_assessed`. The test bundle describes invented data
and review attestations; it is not evidence of a real analysis or human review.

Use [the validation contract](validation_contract.md) for exact behavior,
limitations, error codes, and the restricted JSON Schema profile. External
schema engines can use the schema documents, but still need the R checks for
cross-record relationships, local hashes, and scientific review prerequisites.

## Read the proposal

| Document | Purpose |
| --- | --- |
| [Architecture](architecture.md) | Boundaries, lifecycle, ownership, semantic layer, and skill composition. |
| [Minimum artifact contracts](artifact_contracts.md) | Proposed record model, relationships, validation rules, and lifecycle states. |
| [Executable validation contract](validation_contract.md) | CLI behavior, schema profile, state semantics, and error families. |
| [Bundle schema](schemas/bundle.schema.json) | Typed records, references, nested fields, and controlled vocabularies. |
| [Authoring starters](templates/README.md) | Draft question template and complete synthetic bundle example. |
| [Verification record](verification.md) | Executed regression checks, tested environment, limits, and next hand-off. |
| [Project inventory](project_inventory.md) | Evidence of existing capabilities, gaps, and limits of this inspection. |
| [Adoption and pilot](adoption_plan.md) | Ordered implementation slices and measurable acceptance criteria. |
| [Upstream sources](upstream_sources.md) | Reference projects, intended adaptations, and dependency policy. |

## Intended workflow

```text
question + intended use + audience
  -> analysis plan <-> data contracts + semantic definitions
  -> hypotheses or descriptive questions
  -> analytical implementation -> execution -> validated evidence
  -> insights and claims -> narrative specification
  -> visualization specification -> presentation implementation
  -> scientific, narrative, visual, and reproducibility review
  -> versioned delivery
```

This is an iterative dependency model. A revision may reopen dependent work;
an inconclusive finding or documented exclusion is a valid outcome. Analytical
implementation precedes evidence; presentation implementation consumes it.

## First adoption sequence

1. Review this common design against both projects.
2. Minimum record schemas and validator with synthetic fixtures: implemented.
3. Trace one existing dengue claim through evidence, figure, and report,
   explicitly as a retrospective reconstruction.
4. Test the same generic contracts on a bounded climate methodological review
   and its next prospective decision.
5. Stabilize reusable skills and distribution after both pilots.

Existing repository and project `AGENTS.md` instructions remain authoritative.
Project methodology stays within its project. Common rules must not encode
disease names, climate products, regional definitions, or domain thresholds.

## Implementation boundary

All 14 artifact kinds have typed schemas. The synthetic tests cover a complete
descriptive chain, documentary evidence without an analytical execution,
inconclusive outcomes, hypothesis timing, framework changes, invalid references,
scope/denominator rules, review gates, byte integrity, and stale propagation.

This version supports one project/study per bundle and conservative exact scope
matching. It reads project-provided scope schemas without executing adapter code.
It records declarations of implementation, execution, and human review separately;
it cannot authenticate those declarations or inspect scientific truth or visual
quality. Exact locations are recorded but not parsed within CSVs or HTML.

There is no artifact writer, automatic migration, orchestration skill, renderer,
or publication integration yet. The next bounded task is the retrospective
dengue pilot defined in the [adoption plan](adoption_plan.md).
