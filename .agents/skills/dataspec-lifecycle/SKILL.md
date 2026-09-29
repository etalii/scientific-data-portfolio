---
name: dataspec-lifecycle
description: Determine the next allowed DataSpec step from durable study state, adoption mode, gates and reviews. Use when coordinating a study or adopting DataSpec; does not execute a workflow engine.
---

Inputs: project instructions, selected bundle/revisions, existing authorities,
requested action and available local evidence. Read
[lifecycle and adoption rules](../../../dataspec/v0.2/README.md) and the
[governance reference](../../../dataspec/v0.2/references/governance.md) as needed.

1. Establish retrospective, in_place or native adoption. Retrospective framing
   stays reconstructed; in-place needs a cutover and preserved history. Native
   execution requires a prior workspace registration and analysis-ready gate.
2. Run the version-aware read-only validator from the portfolio root:
   `Rscript dataspec/v0.2/validators/validate.R BUNDLE PROJECT_ROOT`.
3. Inspect findings AND status axes. Machine validity, reproducibility evidence,
   human acceptance and delivery closure are different. No status certifies truth.
4. For blocked inputs, identify the exact missing authority/reference or failed
   gate. For pending human decisions, route to the human-review packet skill.
   Do not infer acceptance from elapsed time or an automated PASS.
5. Select the next authorized responsibility using dependency state. A missing
   visual is not not_required; that branch needs explicit rationale and review.

Output current state, exact blockers/requirements, next permissible step and its
inputs/outputs. Execute that step only within the user's existing authorization.
New revisions preserve previous bytes and review provenance. Never rewrite a
closed pilot to make it appear native to a newer version.
