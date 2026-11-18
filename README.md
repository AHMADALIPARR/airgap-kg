<!--
Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
Research owner: Bel esprit D'accord Trust
Lab: SnapKitty Research Lab
Licensed under the GNU Affero General Public License v3.0 or later.
See LICENSE file for details.
-->

# AIRGAP-KG v0.1

Offline, deterministic reference prototype for evidence-centric RDF graphs.

## Scope
- Strict 7-column TSV ingestion in ISO C11. No network, no language-model dependency.
- Synthetic infrastructure/maintenance observations. No real sensitive intelligence.
- Turtle ontology and SHACL shapes.
- SWI-Prolog visibility-filtered queries and potentially conflicting observation detection.
- SHA-256 integrity manifest using standard local `sha256sum`.

## Build and run

```sh
sh tests/test.sh
swipl -q -s src/reason.pl -- bin/observations.ttl 0
swipl -q -s src/reason.pl -- bin/observations.ttl 1
sha256sum bin/observations.ttl > bin/observations.sha256
sha256sum -c bin/observations.sha256
```

Requires a C11 compiler; Prolog tests require SWI-Prolog `semweb` library.

## Input schema
Seven TAB-separated values per line with no header:
`observation_id asset_id property value source_id classification observed_at`.
IDs are restricted to ASCII letters, digits, `_`, `-`, or `.`; max ID length 96. Timestamp is the fixed lexical form `YYYY-MM-DDTHH:MM:SSZ`. Value is single line, <=512 bytes. Classification: `PUBLIC`, `RESTRICTED`, `SECRET`, `TOP_SECRET`.

## Security boundaries
The Prolog query gate filters classifications *before* inference; this toy predicate is NOT a general graph-store access control system, a NATO/US labeling implementation, a proof of noninterference, or an accreditation-ready cross-domain solution. Data at differing classification levels should be held in separate trust domains for real deployments; never rely solely on user-selectable numeric labels. The harness establishes only the fixture-specific property it tests.

## Known gaps / next gates
1. Authenticated identity, mandatory access control and per-domain storage.
2. Complete SHACL validation using an independently packaged conforming SHACL processor. `shapes.ttl` is provided, but not automatically validated by `tests/test.sh`.
3. Explicit schema validation for real ISO-8601 timestamps; timestamps currently have fixed lexical form but no calendar validity checks.
4. Collision-resistant canonical entity-resolution rules with ambiguity quarantine.
5. Artifact signing and attestation; SHA-256 manifest alone does not authenticate a producer.
6. Immutable append-only evidence ledger and reproducible provenance DAG.
7. Signed offline dependency bundles, filesystem containment, SBOM, package inventory and zero-egress tests.
8. Provenance-safe proof objects; OWL entailment is not implemented in the Prolog predicate.
9. Distinguish contradiction from changing state across time and inconsistent sources.
10. Tests for denial-of-service, parser limits, declassification, graph injection, and covert inference channels.

This project is a reference kernel, not a production C2 system.


## v0.2 Formal verification extension

`formal/EvidenceGate.tla` adds an abstract TLA+ authorization-and-assessment
state machine, TLC config, and a requirements-to-evidence mapping in
`formal/TRACEABILITY.md`. These assets are specifications, not a verified
implementation of the entire pipeline. TLC is not bundled and the model has
not been model-checked in this environment.
