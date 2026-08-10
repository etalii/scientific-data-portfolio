# Project Log

## 2026-08-06 — External TLS chain incident during download integration

During the C.3 integration test, `datos.salud.gob.ar` served the leaf
certificate for `*.salud.gob.ar` without the required intermediate certificate.
Both system `curl` and R/`httr2` failed with `unable to get local issuer
certificate`; no TLS validation was disabled.

The missing issuer was independently identified from Sectigo's official
certificate-chain documentation as `Sectigo Public Server Authentication CA DV
R36`. A temporary CA bundle outside the repository combined the system bundle
with the verified Sectigo intermediate solely for an experiment. With that
bundle supplied only to the relevant processes, `curl`, `httr2`, and both
download integration runs succeeded.

The workaround was not added to project configuration, source code, the
repository, or the system trust store. The temporary bundle was removed after
the test. The preferred long-term resolution is for the external portal to
serve its complete certificate chain.
