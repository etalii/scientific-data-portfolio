# Upstream sources and adaptation policy

These public references were inspected during the initial design discussion on
2026-09-22. This register records conceptual attribution, not installed or pinned
dependencies. Mutable branch links are discovery references. No upstream code
or skill text is vendored by this deliverable.

| Source | Adopted design direction | Boundary or qualification |
| --- | --- | --- |
| [OpenSpec OPSX](https://github.com/Fission-AI/OpenSpec/blob/main/docs/opsx.md) | Discrete artifacts, dependency graphs, editable templates, iterative changes | File existence does not establish analytical acceptance; add evidence and scientific-review requirements. |
| [Data2Story](https://github.com/QinghongLin/data2story-skill) | Evidence-linked claims and visuals; separate editorial, visual, and traceability review | Do not require its agent topology, HTML stack, or media-generation services. |
| [Decision-Grade Data Science](https://github.com/aiopshwang/data-analysis-ml-agent-skills) | Evidence-first lifecycle, explicit intended use, validated claims, reproducible hand-off | This is also the repository named data-analysis-ml-agent-skills; treat it as one source. Descriptive work need not fit an ML workflow. |
| [Storytelling Viz](https://github.com/yudong-94/storytelling-viz-skill) | One defensible takeaway, deliberate chart choice, rendered QA | Retain existing R/Quarto renderers; Plotly is not mandatory. |
| [Graphene](https://github.com/graphene-data/graphene) | Semantic models, analytics as code, agent-accessible validation | SQL/page runtime remains optional; no replacement of R or spatial processing is proposed. |
| [aleberriz/agent-skills](https://github.com/aleberriz/agent-skills) | Independent, composable process/tooling/analytics skills | Several catalog entries, including semantic-layer work, were marked planned; do not assume they are implemented. |
| [mattpocock/skills](https://github.com/mattpocock/skills) | Bounded specs, behavior-focused TDD, disciplined debugging, code review | Adapt engineering practices; do not import unrelated issue-tracker or workflow requirements. |
| [vercel-labs/skills](https://github.com/vercel-labs/skills/tree/main) | Selective discovery, installation, and skill management | Distribution tooling does not provide scientific validation or lifecycle state. |

Before adopting executable code or skill content, record the repository URL,
exact commit, selected paths, license and required notices, local adaptations,
compatibility constraints, and evaluation results. A README-level conceptual
inspection is insufficient to approve an executable dependency. Review upstream
changes deliberately and rerun relevant framework evaluations before updating.

Repository instructions and project scientific contracts remain the local
authority; upstream defaults cannot silently change analysis semantics,
publication permissions, raw-data policy, or environment dependencies.
