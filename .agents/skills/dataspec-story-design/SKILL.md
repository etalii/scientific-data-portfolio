---
name: dataspec-story-design
description: Design evidence-linked narrative and decide whether an analytical visual is required. Use for data-story specifications and their implementation review, not cosmetic changes to an unrelated chart.
---

Inputs: claim revisions, evidence/scope, audience and communication purpose.
Preserve canonical claim text/meaning; propose editorial changes explicitly.

1. Select and order claims, context sources and mandatory caveats. Record excluded
   candidates and reasons. Do not hide new scientific claims in narrative prose.
2. Decide required, not_required or undecided visualization. Missing output is
   not an exemption. Use a visual only if it adds analytical interpretation;
   document why a table or prose suffices otherwise.
3. If required, write the visual specification before implementation: purpose,
   claim/metric links, encoding, units, scale, annotations and QA. If not_required,
   preserve the rationale and obtain the corresponding human narrative review.
4. Distinguish exact strings from semantically constrained editorial realization
   with the [comparison policy template](../../../dataspec/v0.2/templates/wording_policy.md).
   Never infer semantic equivalence from a literal mismatch automatically.
5. Review implementation against the specification and evidence. Changes to
   claims require new revisions and review, not only a prettier figure.

Outputs: narrative specification, explicit visualization decision, optional
visual specification, implementation/check references and editorial review needs.
See [branches and delivery](../../../dataspec/v0.2/README.md); do not add a dummy
visual to close a study. Rendering/deployment remain separate responsibilities.
