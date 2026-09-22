# Minimum validator verification

Date: 2026-09-22. Scope: DataSpec implementation slice 1, version 0.1.0.
This is an engineering verification record, not scientific certification.

## Executed checks

Command, from the portfolio root:

```bash
Rscript dataspec/tests/run_tests.R
```

Result: **48 regression scenarios passed**, exit code 0, using R 4.1.2,
jsonlite 2.0.0, and digest 0.6.39. Dependency versions match `renv.lock`.

The suite checks all 14 artifact kinds across the base fixture and in-memory
variants. It covers computational and documentary provenance, inconclusive
results, timing evidence, framework bootstrap changes, typed references,
dependency closure/cycles, candidate revisions, scope and denominator rules,
human-review requirements, narrative claim mapping, and file integrity.

Fault-injection tests verify stale propagation after a byte or revision change,
preservation of unrelated records, symlink/path escape rejection, deterministic
reports, and no file changes from validation. CLI checks cover running outside
the repository, success (0), invalid bundles (1), and malformed JSON/usage (2).

Documentation links, JSON parsing, whitespace, and fenced blocks were checked.
No changes were made to either scientific project's tracked files. Pre-existing
untracked climate files were left in place. No acquisition, scientific pipeline,
render, publication, dependency installation, or external skill installation ran.

## Boundaries

The local R implementation checks a documented subset of JSON Schema, not the
entire standard. An independent full JSON Schema engine was unavailable in the
environment; no cross-engine compatibility certification is claimed. Consumers
of the standalone record schema must resolve its sibling bundle schema locally.

Passing results establish structural and declared-provenance consistency only.
The validator does not execute analyses, authenticate reviewer identities,
inspect chart rendering, parse source locators, or determine whether source text
scientifically supports a claim. Human review is a recorded prerequisite, not
an independently verified event. Scope compatibility currently requires exact
equality under the declared project scope schema.

## Next hand-off

The next bounded unit is the retrospective dengue pilot in
[the adoption plan](adoption_plan.md). Before writing project records, establish
its actual input availability, exact contract/configuration revisions, baseline
hashes, and authorized metadata paths. New shared skills and project migration
remain outside this implementation slice.
