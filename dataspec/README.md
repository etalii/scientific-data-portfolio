# DataSpec

DataSpec connects questions, analytical authorities, reproducible evidence,
qualified claims, narrative, purposeful visualization and human review through
versioned filesystem artifacts. Projects retain their scientific contracts.

**Current implementation for review: [DataSpec v0.2](v0.2/README.md).** It adds
explicit visual/nonvisual delivery, per-item human dispositions, bounded
reproducibility and workspace prospective registration. It keeps technical
validity, human acceptance and scientific certification separate.

```sh
# Dual-version read-only entrypoint (0.1 and 0.2):
Rscript dataspec/v0.2/validators/validate.R BUNDLE PROJECT_ROOT
# Historical suite, new semantics, and immutable-pilot compatibility:
Rscript dataspec/tests/run_tests.R
Rscript dataspec/v0.2/tests/run_tests.R
Rscript dataspec/v0.2/tests/pilot_compatibility.R
```

No analysis, migration, acquisition, publication or scientific approval is
performed by validation. Exit 0 means supplied structure and linkage passed;
certification remains not_assessed. Example reviews are synthetic declarations,
not real human approval. Existing project raw/generated-file policies apply.

| Document | Purpose |
|---|---|
| [v0.2 architecture delta](v0.2/architecture_delta.md) | Cross-pilot evidence, classification and minimal decisions |
| [v0.2 guide](v0.2/README.md) | Lifecycle, adoption, status axes, skills and limits |
| [v0.2 governance contract](v0.2/references/governance.md) | Typed fields and validation semantics |
| [v0.2 schema](v0.2/schemas/bundle.schema.json) | Closed versioned envelope and records |
| [v0.2 verification](v0.2/verification.md) | Executed checks, invariants, compatibility and scope |
| [v0.1 architecture](architecture.md) | Historical proposal; newer semantics are defined in v0.2 |
| [v0.1 contracts](artifact_contracts.md) | Original record responsibilities |
| [v0.1 validation contract](validation_contract.md) | Preserved historical executable behavior |
| [Upstream references](upstream_sources.md) | Design influences; no mandatory remote dependency |

The original `schemas/`, `validators/validate.R`, `validators/core.R`, fixtures and
48-scenario suite remain unchanged. The two closed pilot bundles remain 0.1:
[dengue closure](../argentina-dengue-analysis/dataspec/studies/rank_shift_2024/closure.md)
and [climate closure](../climate-biodiversity-vulnerability-argentina/dataspec/studies/bio01_pair_eligibility/closure.md).
Their history is not rewritten to pretend they used v0.2. A transient compatibility
interpretation demonstrates that climate's nonvisual delivery is representable
without inventing a figure or new human acceptance.

Five lightweight repository skills route, coordinate lifecycle, assemble/review
evidence, design the story/visual branch and prepare/apply human decisions. See
[skill architecture](v0.2/README.md#skills). Existing contract/comparability,
geographic, rate, Quarto and publication skills retain their scopes.
