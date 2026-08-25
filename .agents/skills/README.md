# Scientific Data Portfolio skill catalog

These repository-level skills capture reusable operating procedures from
completed projects. They complement, but do not replace, the repository's
always-on `AGENTS.md` governance rules. They are instruction-only: each is
loaded only when its trigger applies.

## Candidate assessment

| Candidate | Job to be done | Reusable outside the source project | Overlap decision | Scope | Decision |
| --- | --- | --- | --- | --- | --- |
| `contract-first-data-pipeline` | Design or extend a staged data pipeline through explicit contracts and regression certification. | Yes | Absorbs the regression-audit candidate because regression is a closing phase of each stage. | Repository root | Create |
| `scientific-data-comparability-audit` | Decide whether cross-period, cross-source, or cross-geography comparisons are supported. | Yes | Deliberately excludes denominator construction and geographic mapping implementation. | Repository root | Create |
| `population-adjusted-rate-analysis` | Build and interpret descriptive rates using documented population denominators. | Yes | Consumes validated mappings and comparison evidence; does not replace either audit. | Repository root | Create |
| `geographic-crosswalk-validation` | Create auditable mappings from source geography to a reference geography. | Yes | Limited to mapping and mapping completeness, not rates or spatial modelling. | Repository root | Create |
| `quarto-report-certification` | Certify a rendered report whose analytical inputs are already closed. | Yes | Stops before deployment; static publication is separate. | Repository root | Create |
| `portfolio-static-publication` | Deploy already-certified static artifacts and verify the public route. | Yes | Does not render, regenerate figures, or certify analysis. | Repository root | Create |
| `pipeline-regression-audit` | Re-check closed artifacts after a stage change. | Yes | Merged into `contract-first-data-pipeline` to avoid a duplicate lifecycle skill. | — | Merge |

## Derived-from evidence

| Skill | Purpose | Derived from | Scope |
| --- | --- | --- | --- |
| `contract-first-data-pipeline` | Contract-led stage delivery and regression closure. | C.1--C.10 contracts, acquisition/validation atomicity, and staged Git history. | Repository root |
| `scientific-data-comparability-audit` | Evidence-based comparison eligibility. | C.5--C.7 structural/quality work and C.11--C.13 comparability assessment. | Repository root |
| `population-adjusted-rate-analysis` | Denominator-aware descriptive indicator construction. | C.14--C.16 reference, mapping, and indicator contracts. | Repository root |
| `geographic-crosswalk-validation` | Conservative geographic reference mapping. | C.15 geographic-reference contract and validation snapshot. | Repository root |
| `quarto-report-certification` | Reproducible publication-render certification. | C.20, Quarto report certification, generated-file policy, and portfolio QA. | Repository root |
| `portfolio-static-publication` | Static deployment of certified outputs. | GitHub Pages workflow and publication certification. | Repository root |

## Governance boundary

Keep rules that apply to every task in `AGENTS.md`: immutable raw data,
provenance, single-responsibility scripts, centralized project conventions,
documentation, and Git hygiene. Use these skills for conditional workflows that
need contracts, decision points, stop conditions, and a verifiable deliverable.

## Trigger smoke tests

| Skill | Positive prompts that should trigger | Negative prompts that should not trigger |
| --- | --- | --- |
| `contract-first-data-pipeline` | “Design a contract before adding a data-ingestion stage.”; “Extend this pipeline without changing closed outputs.” | “Rename one plotting variable.”; “Explain this CSV column.” |
| `scientific-data-comparability-audit` | “Can annual totals be compared after a schema change?”; “Assess whether these sources support a regional trend.” | “Summarize one certified table.”; “Make a figure legend larger.” |
| `population-adjusted-rate-analysis` | “Build rates using official population projections.”; “Audit whether this rate can be called incidence.” | “Count records by category.”; “Map source place names.” |
| `geographic-crosswalk-validation` | “Validate IDs and names before joining geography.”; “Measure completeness of a source-to-region mapping.” | “Calculate a national rate.”; “Write a report abstract.” |
| `quarto-report-certification` | “Certify this Quarto HTML before publication.”; “Check deterministic rendering and portable assets.” | “Deploy an already-certified HTML.”; “Generate an analysis table.” |
| `portfolio-static-publication` | “Deploy this certified HTML to GitHub Pages.”; “Verify the public URL before updating a README CTA.” | “Render the Quarto source.”; “Recompute the figures.” |

## Discovery note

Repository skills are located at `.agents/skills/<skill-name>/SKILL.md`. This
session may not refresh newly created skills automatically. Start a new Codex
session and use explicit invocation (for example, `$contract-first-data-pipeline`)
to confirm discovery before relying on implicit selection.
