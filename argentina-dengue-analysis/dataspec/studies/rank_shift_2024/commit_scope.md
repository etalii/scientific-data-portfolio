# Dedicated retrospective dengue pilot commit boundary

The following files comprise the original technical pilot and its explicitly
authorized human-review closure. Root DataSpec changes are status/hand-off
documentation only; common executable contracts and skills are unchanged.

```text
README.md
argentina-dengue-analysis/.gitignore
argentina-dengue-analysis/config/project.yml
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/acceptance.json
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/audit.json
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/baseline.json
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/baseline_project.yml
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/bundle.json
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/checks.json
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/environment.json
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/mutation_checks.json
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/report_fragment.html
argentina-dengue-analysis/data/metadata/dataspec_rank_closure_v1/validation.json
argentina-dengue-analysis/data/metadata/dataspec_rank_pilot_v1/audit.json
argentina-dengue-analysis/data/metadata/dataspec_rank_pilot_v1/baseline.json
argentina-dengue-analysis/data/metadata/dataspec_rank_pilot_v1/baseline_project.yml
argentina-dengue-analysis/data/metadata/dataspec_rank_pilot_v1/bundle.json
argentina-dengue-analysis/data/metadata/dataspec_rank_pilot_v1/checks.json
argentina-dengue-analysis/data/metadata/dataspec_rank_pilot_v1/environment.json
argentina-dengue-analysis/data/metadata/dataspec_rank_pilot_v1/mutation_checks.json
argentina-dengue-analysis/data/metadata/dataspec_rank_pilot_v1/validation.json
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/README.md
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/accepted_report.qmd
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/closure.md
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/commit_scope.md
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/framework_feedback.md
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/human_decision_request.txt
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/human_decisions.yml
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/pre_closure_project.yml
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/review.md
argentina-dengue-analysis/dataspec/studies/rank_shift_2024/scope.schema.json
argentina-dengue-analysis/docs/dataspec_rank_closure_contract.md
argentina-dengue-analysis/docs/dataspec_rank_pilot_contract.md
argentina-dengue-analysis/scripts/processing/22_build_dataspec_rank_trace.R
argentina-dengue-analysis/scripts/processing/23_close_dataspec_rank_pilot.R
argentina-dengue-analysis/scripts/validation/21_audit_dataspec_rank_pilot.R
argentina-dengue-analysis/tests/validation/test_dataspec_rank_closure.R
argentina-dengue-analysis/tests/validation/test_dataspec_rank_pilot.R
dataspec/README.md
dataspec/adoption_plan.md
dataspec/verification.md
```

Excluded: every climate project file; raw/reference/processed analytical data;
temporary reproduction workspaces; unchanged original figures, published report,
QMD, and common schemas/validator. The only new generated HTML is the explicitly
contract-designated accepted fragment. The JSON/YAML provenance exceptions are
designated by the pilot and closure contracts. No push is part of this commit.

Validation before commit: 48 common scenarios, six original dengue tests, four
closure scenario groups, 21 audit controls, 20 resolving records, valid external
hashes, zero unresolved review findings, and unchanged six indicators/PNG.
`git diff --check` and the staged equivalent must pass before committing.
