# DataSpec architecture proposal

## Scope and authority

DataSpec v0.1 proposes a protocol for durable analytical hand-offs and their
communication. Scientific eligibility remains governed by project contracts.
DataSpec checks linkage and records review decisions; it cannot infer scientific
validity from file existence, a successful process exit, or a polished figure.

The common framework owns record structure, dependency rules, generic
validators, templates, and operating procedures. Projects own questions,
methods, data contracts, metric definitions, evidence, claims, and deliverables.
Each artifact has one named owning role and explicit consumers. Roles need not
be separate agents; this design does not require multi-agent execution.

## Proposed layout

The common schemas, starter template, R validator, and synthetic tests below
are implemented. Project-local records and new skills remain planned:

```text
dataspec/
  schemas/                  shared machine-readable record contracts
  templates/                minimal authoring forms
  validators/               generic R validators
  tests/                    synthetic positive and negative fixtures
.agents/skills/              existing and future common procedures
<project>/
  config/project.yml        authoritative project configuration
  dataspec/
    semantic/               project definitions referencing existing contracts
    studies/<study_id>/     question, plan, evidence, claims, and specifications
    changes/<change_id>/    rationale, affected references, tasks, and review
```

Paths above describe responsibilities, not an instruction to create empty
directories. Add a directory with its first real consumer. Configurable paths,
thresholds, sources, and scope parameters stay in `config/project.yml` under
the existing project conventions. DataSpec must not introduce a competing
`project.yml` inside `dataspec/`. A future configuration extension needs its
own compatibility review before producer or consumer implementation.

## Artifact flow and change management

A study records one bounded question and its supported outcomes. A change
records a revision to a study, contract, or framework capability. These are
different identities: one study can have several changes and executions.

Within an exact set of record revisions, `depends_on` forms an acyclic graph.
Iterations create new revisions rather than cycles or replacement of historical
evidence. Supporting and contradicting evidence are explicit claim relations.

An upstream change does not silently refresh downstream status. Consumers of
the changed revision and their transitive dependents become stale relative to
the proposed new delivery until reviewed. The original versioned delivery
remains a historical record of its original inputs and review.

Contract changes, method changes, new analyses, and wording-only changes have
different impacts. A change record identifies which validations need repeating
and why. A correction to a public claim requires a new reviewed delivery;
history is retained.

## Semantic layer and analytics as code

A semantic definition records grain, units, population or domain, time basis,
dimensions, allowed aggregation and joins, missingness rules, computation
authority, and interpretation limits. It references the existing contract and
producer rather than creating an independently editable copy of their formula.
Conflicts between a definition and its governing contract block acceptance.

The generic system knows that a metric has a denominator or a spatial support;
only the project defines their scientific meaning. Domain-specific eligibility
checks belong in project validators invoked through an explicit adapter.

R scripts remain analytical producers. Quarto and visualization scripts consume
reviewed analytical artifacts without hidden recomputation. Each execution
records the command, code/configuration/environment identities, input/output
hashes, and verification result. Code and reproducible execution, not prose
alone, establish computational provenance.

Graphene is an architectural reference for semantic models and analytics as
code. An executable Graphene adapter is optional future work requiring a
demonstrated SQL or dashboard use case, compatibility tests, and a documented
dependency decision. Raster processing is not delegated to it by this proposal.

## Skills and composition

Reuse the existing [skill catalog](../.agents/skills/README.md). Contract-first
delivery, comparability, geographic crosswalks, population-adjusted rates,
Quarto certification, and static publication retain their current boundaries.

Candidate additions, to be justified by the pilots:

| Responsibility | Inputs | Output |
| --- | --- | --- |
| Question and plan framing | Context, intended use, available source assessment | Bounded question and analysis plan |
| Semantic definition | Governing contracts and computation references | Reviewed metric definitions |
| Evidence and claim registration | Executions, documentary sources, findings | Evidence records and qualified claims |
| Narrative specification | Reviewed claims, audience, communication goal | Ordered story with caveats and claim references |
| Visualization specification | Claims, metrics, display requirements | Chart encoding and visual acceptance criteria |
| Traceability review | Exact candidate delivery and dependency closure | Linkage findings and review record |

A lightweight lifecycle coordinator selects applicable procedures and reports
missing artifacts. It does not replicate specialist logic. Each skill declares
triggers, exclusions, required inputs, owned output, failure conditions, and
validation. Instructions guide judgment; deterministic validators enforce
machine-checkable rules. Positive and negative trigger evaluations must cover
both projects before common skills are considered stable.

## Review and delivery

Scientific review evaluates whether evidence supports the wording and scope.
Narrative review checks context, alternatives, uncertainty, and selection bias.
Visual review checks numerical fidelity, encodings, labeling, accessibility,
and the rendered output. Reproducibility review checks exact inputs, code,
environment, execution evidence, and known reproduction limits.

Record reviewer identity and review mode; never claim independent review when
the producer also performed the review. An automated link check cannot replace
methodological disposition. Certification and publication remain separate.

## Persistence and adoption safety

Human-authored specifications, schemas, tests, and skills are version-controlled.
Exact evidence/run/review manifests may become versioned provenance metadata
only when a project contract explicitly designates their schemas and paths.
Generated datasets, logs, renders, and figures retain their existing policies;
DataSpec introduces no blanket exception to Git rules.

Accepted record revisions are immutable. Corrections create a new revision with
a reason and supersession link. Future writers publish a validated record or
bundle atomically from a temporary on the destination filesystem and reject
identity/content conflicts. Raw inputs are never edited. Adoption does not
re-run acquisition or change an existing published deliverable by default.
