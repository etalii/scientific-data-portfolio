# Initial project inventory

Inspection date: 2026-09-22. Scope: repository instructions, architecture,
contracts, skill catalog, and file inventory. This is a documentation and
implementation-presence assessment, not a new scientific certification. No
pipeline, test suite, report render, or public-route verification was executed.

## Common foundation

The [root instructions](../AGENTS.md) require immutable raw data, provenance,
single-responsibility R scripts, explicit transformations, and controlled
generated-file tracking. Their purpose statement still emphasizes the first
epidemiological project; a future governance update should describe the broader
portfolio while retaining project-specific scientific policies locally.

The [six existing skills](../.agents/skills/README.md) already supply contract-led
stage delivery, comparability assessment, crosswalk validation, denominator-aware
rates, report certification, and static publication. No skill replacement is
needed for this proposal. Their operating instructions are not yet a shared
machine-readable study/evidence/claim model.

## Argentina Dengue Analysis

| Capability | Repository evidence | Adoption consequence |
| --- | --- | --- |
| Staged acquisition and analysis | [Architecture](../argentina-dengue-analysis/docs/project_architecture.md) and its contract references | Reuse existing artifact ownership and producer boundaries. |
| Explicit analysis methodology | [Analysis protocol](../argentina-dengue-analysis/docs/analysis_protocol.md) | Map documented questions and methods; do not invent historical pre-specification. |
| Denominator-aware indicators | [C.16 contract](../argentina-dengue-analysis/docs/published_count_rate_indicators_contract.md) | Register metric semantics, scenario, eligibility, and exact evidence references. |
| Figures with bounded interpretation | [C.20 contract](../argentina-dengue-analysis/docs/epidemiological_portfolio_visualization_contract.md) | Reuse figure IDs, certified-input requirements, and scope/caption rules. |
| Existing public-facing story | [Project README](../argentina-dengue-analysis/README.md) and [Quarto source](../argentina-dengue-analysis/reports/argentina_dengue_portfolio.qmd) | Locate claims in both report and chart; current documentation describes these as certified deliverables. |

The proposed pilot concerns calendar-year 2024 provincial count/rate ordering
under the contemporary denominator scenario. The README reports Buenos Aires
moving from rank 1 to 16 and Tucuman from 3 to 1. These are existing claim
candidates to reconcile against exact inputs, not values independently verified
by this inventory. The separate epidemiological season is outside that pilot.

Main gaps to assess: machine-readable claim IDs, run-to-evidence linkage,
semantic references, narrative specifications, exact claim locations, and
propagation of stale status. Existing files may already document parts of these;
the pilot must map them before adding new records.

## Climate-driven Biodiversity Vulnerability

| Capability | Repository evidence | Adoption consequence |
| --- | --- | --- |
| Scientific eligibility and claim limits | [Project instructions](../climate-biodiversity-vulnerability-argentina/AGENTS.md) and [architecture](../climate-biodiversity-vulnerability-argentina/docs/project_architecture.md) | Keep suitability, distribution, and conservation interpretation local. |
| Recorded methodological decisions | [Decision log](../climate-biodiversity-vulnerability-argentina/docs/methodological_decision_log.md), including D0035-D0039 | Import historical decisions with dated evidence and origin labels. |
| Separate structural and semantic contracts | [Raster profile](../climate-biodiversity-vulnerability-argentina/docs/climate_raster_structural_profile_contract.md), [semantic review](../climate-biodiversity-vulnerability-argentina/docs/climate_semantic_comparability_contract.md), [value checks](../climate-biodiversity-vulnerability-argentina/docs/climate_value_check_contract.md) | Test multiple evidence types without conflating their scientific scope. |
| Implementation files exist | [Semantic producer](../climate-biodiversity-vulnerability-argentina/scripts/processing/07_build_climate_semantic_review.R), [validator](../climate-biodiversity-vulnerability-argentina/scripts/validation/10_validate_climate_semantic_review.R), and [tests](../climate-biodiversity-vulnerability-argentina/tests/processing/test_climate_semantic_review.R) | Presence establishes implementation candidates, not execution success or certification. |
| Status documentation needs reconciliation | [README](../climate-biodiversity-vulnerability-argentina/README.md) still describes Stage 00 and no climate acquisition | Establish status from contracts, code, manifests, and validation evidence before editing the summary. |

The decision log contains historical scopes that deferred implementation; later
producer files are now present. Neither the old scope nor current file presence
alone determines execution state. Reconcile contract/configuration versions and
run records before selecting a specific review bundle.

The working tree also contains pre-existing untracked climate source/download
files. Their presence does not establish governed acquisition or eligibility.
This deliverable leaves them untouched and does not import them as evidence.

## Shared gaps and ownership

| Gap | Common responsibility | Project responsibility |
| --- | --- | --- |
| Question-to-result traceability | Record identities and relation validation | Scientific question, evidence, and interpretation |
| Metric ambiguity | Required semantic fields and references | Units, formulas, grain, scope, and allowable joins |
| Narrative provenance | Claim/location mapping and source checks | Wording, caveats, and scientific support |
| State drift | Separate specification, implementation, execution, certification | Supply exact records supporting each state |
| Re-review after changes | Dependency impact and stale detection | Decide scientific impact and repeat relevant checks |

Dengue provides the retrospective end-to-end pilot. Climate tests portability
and prospective use on methodological work before a final biodiversity story.
Other repository directories are outside this first inventory.
