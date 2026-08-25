---
name: quarto-report-certification
description: Certify a Quarto report after its analytical artifacts are already closed, including render determinism, content QA, portability, and generated-file policy. Do not use to build analysis outputs, regenerate figures, or deploy a static site.
---

# Quarto report certification

## Goal

Demonstrate that a report faithfully and reproducibly presents already-certified
artifacts without triggering hidden analytical work.

## Preconditions

1. Identify the approved source document, expected rendered artifact, input
   artifacts, and their applicable contracts or hashes.
2. Confirm the report task is authorized separately from any upstream pipeline
   execution. Do not run analytical stages merely to make a render succeed.
3. Check Quarto installation and the project environment only to the degree
   needed for rendering. Treat Quarto CLI as external tooling unless the project
   explicitly manages it otherwise.

## Render and inspect

- Render from the documented project root using the declared command.
- Capture warnings and errors. Stop on a missing required dependency, an
  unexpected upstream mutation, or a render that changes certified inputs.
- Check the rendered HTML for title, table of contents, required sections,
  figures, tables, citations, bibliography, internal links, and declared
  accessibility text.
- Inspect terminology and numerical spot checks against certified artifacts.
  Preserve stated scope, numerator meaning, caveats, and non-causal limits.
- Check for local absolute paths, `file://` links, missing assets, visible TODOs
  or placeholders, and code that should be hidden in the published report.

## Determinism and policy

1. Render twice without changing inputs.
2. Compare hashes or bytes. Investigate any difference before declaring a
   deterministic render.
3. Confirm whether the generated HTML belongs in version control under the
   repository's generated-file policy. Do not stage unrelated render caches or
   temporary files.
4. Hash designated upstream artifacts before and after certification when their
   immutability is part of the report guarantee.

## Deliverable

Report tooling status, render warnings, output hash, double-render result,
content and portability checks, upstream immutability, and any blocker before
publication. Use a static-publication workflow separately to deploy the result.
