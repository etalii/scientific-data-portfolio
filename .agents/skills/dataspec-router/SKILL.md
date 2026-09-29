---
name: dataspec-router
description: Select the applicable DataSpec responsibility for a scientific study adoption, evidence, story, or closure task. Use for routing across responsibilities, not ordinary data edits.
---

Read repository/project instructions and the requested study's files first. Route
by the user's intended outcome, not by keywords or an artifact filename:

- Unknown state, adoption/cutover, blocked work or next permitted step:
  `dataspec-lifecycle`.
- Reproduced outputs becoming evidence or claims, or support assessment:
  `dataspec-evidence-review`.
- Evidence-linked communication, chart choice or a justified nonvisual result:
  `dataspec-story-design`.
- Human decision packet or applying explicit decisions:
  `dataspec-human-review`.
- New pipeline authority or hand-off contracts: existing
  `contract-first-data-pipeline`; do not duplicate its contracts.
- Domain comparison eligibility: existing `scientific-data-comparability-audit`.

Output the selected responsibility, observed input paths and why it applies.
Invoke only relevant skills. Do not start a lifecycle, acquisition, publication,
commit or approval request merely because routing found a possible next step.
Read [the central guide](../../../dataspec/v0.2/README.md) only when version,
adoption or responsibility boundaries are unclear.
