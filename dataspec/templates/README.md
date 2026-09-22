# Authoring starters

[question.json](question.json) is a draft record template. Replace the project,
study, owner, timestamp, question, scope, and all placeholder text before using
it. It is not a complete bundle and must not be presented as a reviewed artifact.

The [synthetic bundle](../tests/fixtures/minimal/bundle.json) demonstrates the
minimum complete descriptive chain, including nested fields and exact references.
Its project root is [the fixture directory](../tests/fixtures/minimal), whose
assets are deliberately invented, authored test inputs. Do not copy its review
attestations, execution dates, or results into a real study.

For a real study, first select the project scope schema and define authorized
record paths under its existing `config/project.yml` conventions. Preserve the
governing contract's identity and version, identify actual source bytes and
locators, and record gaps explicitly. A bundle uses one project and study;
framework change bundles use project `dataspec` with null study identifiers.

Refer to [the schema](../schemas/bundle.schema.json) for all 14 record payloads
and [the validation contract](../validation_contract.md) for semantic conditions
that cannot be expressed by shape alone. No writer, project adapter migration,
or acceptance automation is installed by these starter files.
