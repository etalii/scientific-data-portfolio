# Synthetic regression suite

Run from the portfolio root:

```bash
Rscript dataspec/tests/run_tests.R
```

The base-R harness needs only the dependencies declared in DataSpec's
`DESCRIPTION` and `renv.lock`. No network access, pipeline execution, renderer,
or package installation is performed. CLI tests run from outside the repository
and verify successful validation, invalid bundles, malformed JSON, and bad usage.

The fixture bundle and assets are hand-authored synthetic test inputs, permitted
in Git as tests. `result.csv` is an invented expected example, not generated
project data. Execution and review records are fictional attestations used to
exercise validation; no real reproduction or scientific certification is claimed.

Valid cases cover computational, documentary, inconclusive, hypothesis, and
framework-change records. Negative cases alter copies in memory or a temporary
directory. They exercise schema/type errors, identities, graph closure and
cycles, scope and denominator rules, timing, review coverage, claim mapping,
unavailable evidence, filesystem boundaries, hash mismatch, and stale propagation.

The suite verifies deterministic results, stable output when record order changes,
and byte-for-byte preservation of files read by the validator. Temporary mutation
cases never operate on either portfolio project's data. The validator intentionally
does not decide whether a source actually supports prose; a source with no passing
human-review attestation cannot satisfy delivery requirements.
