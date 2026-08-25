---
name: portfolio-static-publication
description: Publish an already-certified static project artifact through a minimal GitHub Pages or equivalent static-hosting workflow, then verify the real public route before adding navigation links. Do not use to render Quarto, execute analyses, regenerate figures, or publish uncertified outputs.
---

# Portfolio static publication

## Goal

Deploy a certified static artifact without broadening the deployment workflow
into an analytical build, and verify the public experience before linking to it.

## Preconditions

- Record the approved source artifact and its SHA-256 or byte identity check.
- Identify the intended site root, project subpath, generated-file policy, and
  repository authorization for commit, push, and deployment.
- Keep rendering and certification separate. If the artifact is not certified,
  stop and use the report-certification workflow first.

## Workflow design

1. Trigger only on the certified static artifact and workflow changes, plus an
   explicit manual dispatch path.
2. Use minimal permissions appropriate to the host. For GitHub Pages, keep
   content read, Pages write, and identity-token write permissions narrowly
   scoped.
3. Build the deploy artifact only by creating required directories, generating a
   minimal neutral root entry when a monorepo requires one, and copying certified
   files to their stable public subpaths.
4. Verify each copy with `cmp` or a SHA-256 check before upload. Do not invoke
   R, package restoration, Quarto, data acquisition, analysis scripts, or
   figure generation in the deploy workflow.
5. Keep temporary site directories out of the working tree and out of Git.

## Public certification

After an authorized commit and push, verify the actual workflow run, each
preparation/upload/deploy job, deployment environment, and the URL emitted by
the platform. Then check the root landing and public artifact for HTTP success,
title, required content, figures/assets, links, portability, and absence of
local paths or visible placeholders.

Only after the public route is confirmed may a project README or similar CTA be
updated to that exact URL. Make that navigation update a separate, minimal
commit when practical.

## Stop conditions

Stop on an uncertified source hash, a workflow that builds analytical artifacts,
an unsuccessful deployment, a route that differs from the expected path, broken
assets, or a public page that fails content/portability checks. Do not guess a
public URL.

## Deliverable

Report the source and deployed hashes, workflow and environment status, actual
public URL, smoke-test results, navigation changes, final Git status, and any
remaining blocker.
