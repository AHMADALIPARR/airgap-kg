<!--
Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
Research owner: Bel esprit D'accord Trust
Laboratory: SnapKitty Research Lab
Licensed under the AIRGAP-KG Research and Demonstration License.
See LICENSE file for full terms.
-->

# AIRGAP-KG

**Offline, Deterministic Evidence-Centric Knowledge Graph Kernel**  
*Reference implementation with machine-checked formal models*

---

## Executive Summary

AIRGAP-KG is a deliberately constrained reference kernel for building evidence-centric knowledge graphs in environments where network connectivity is unavailable, untrusted, or explicitly prohibited. Every observation that enters the system is treated as structured evidence: it carries provenance, a classification label, a timestamp, and a clear chain of custody from raw input through validated graph to clearance-filtered query result.

The prototype is intentionally small, fully offline, and free of language-model or external-service dependencies. Its value lies in making security and correctness properties *explicit and checkable*:

- Strict lexical and structural validation before any output is produced.
- Classification filtering applied *before* any deduction.
- An abstract TLA+ model of the evidence-acceptance, assessment, approval, and publication workflow.
- A self-composed hyperproperty model that checks observational noninterference on the low-published view.
- Companion prototypes in Awk, Erlang, Cryptol, and SAW that illustrate selected next-step capabilities (calendar-valid timestamps, append-only ledgers, and high-assurance hashing).

AIRGAP-KG is not a production command-and-control system. It is a precise, auditable foundation that later systems can refine while preserving the invariants already stated in the formal models.

---

## Design Principles

1. **Air-gap by construction**  
   No network sockets, no remote fetches, no external language-model calls. The entire pipeline runs on local files and standard tools.

2. **Evidence first**  
   Every fact is an observation with an identifier, asset, property, value, source, classification, and timestamp. There is no untyped triple store.

3. **Fail closed, never partial**  
   The C11 ingest program validates the entire input before opening the output file. A malformed record produces no graph fragment.

4. **Filter before inference**  
   The Prolog query layer selects only clearance-eligible assertions before any further reasoning. High-classified data is never materialized for a low clearance.

5. **Formal models as contracts**  
   The TLA+ specifications state the authorization and assessment obligations independently of any particular implementation language. Implementations are expected to refine these models.

6. **Determinism and reproducibility**  
   Given the same input and the same clearance, the observable results are identical across runs and machines that possess a conforming C11 compiler and SWI-Prolog.

---

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌────────────────────┐
│  TSV fixtures   │────▶│  C11 ingest.c    │────▶│  Turtle graph       │
│  (7-column)     │     │  (pre-validate)  │     │  (observations)     │
└────────────────┘     └──────────────────┘     └──────────┬─────────┘
                                                             │
                                                             ▼
┌─────────────────┐     ┌──────────────────┐     ┌────────────────────┐
│  Clearance      │────▶│  Prolog reason.pl│◄────│  SHACL shapes       │
│  (0–3)          │     │  (filter first)  │     │  (optional)         │
└────────────────┘     └────────┬─────────┘     └────────────────────┘
                                 │
                                 ▼
                        Visible observations
                        + conflict reports
```

Supporting formal layer:

- `formal/EvidenceGate.tla` — abstract state machine for accept/reject, assess, approve, publish.
- `formal/EvidenceGateHyper.tla` — self-composition checking observational noninterference.
- `formal/TRACEABILITY.md` — mapping of invariants to representative NIST control families.
- Cryptol / SAW prototypes for future high-assurance integrity primitives.

---

## Core Components

### Ingestion (`src/ingest.c`)

ISO C11 program that:

- Accepts a seven-column TSV (observation_id, asset_id, property, value, source_id, classification, observed_at).
- Enforces strict lexical rules: token characters and length limits, closed set of classification labels, fixed timestamp form `YYYY-MM-DDTHH:MM:SSZ`, value length and control-character restrictions.
- Performs a complete validation pass before creating any output file.
- Emits clean Turtle using the project vocabulary.

### Reasoning (`src/reason.pl`)

SWI-Prolog program that:

- Loads the generated Turtle with imports disabled.
- Defines numeric clearance levels (PUBLIC=0 … TOP_SECRET=3).
- Exposes an `observation/7` predicate that succeeds only for assertions whose classification is ≤ the supplied clearance.
- Detects potential conflicts (same asset + property, differing values) under the same clearance filter.
- Never applies classification filtering after inference.

### Ontology and Shapes

- `ontology/core.ttl` — minimal OWL vocabulary (Observation, Asset, Source and their properties).
- `ontology/shapes.ttl` — SHACL NodeShape requiring exactly one of each mandatory property and a closed classification set.

### Formal Models

- **EvidenceGate** — small abstract transition system with five key invariants (no evidence conflict, no unsupported verdict, no false approval, no unapproved release, no unauthorized release).
- **EvidenceGateHyper** — self-composed variant that reduces a 2-safety observational noninterference hyperproperty to an ordinary invariant checkable by TLC.
- Traceability document linking each invariant to starting points in NIST SP 800-53 and SP 800-171.

### Supporting Prototypes

| Language | Location | Purpose |
|----------|----------|---------|
| Awk | `src/awk/validate_timestamps.awk` | Calendar-valid timestamp checks beyond pure lexical form |
| Erlang | `src/erlang/evidence_ledger.erl` | Append-only hash-chained evidence ledger |
| Cryptol | `formal/cryptol/EvidenceHash.cry` | Toy high-assurance MAC / hash skeleton |
| SAW | `formal/saw/verify_evidence_hash.saw` | Verification script for the Cryptol properties |

---

## Security Boundaries (Explicit Non-Claims)

The prototype makes its limits clear so that later work can strengthen them without surprising changes in observable behavior:

- Classification filtering is performed before deduction, but the current implementation relies on disciplined use of the filtered predicates. A production refinement would embed the same filter in a reference monitor.
- The SHA-256 manifest authenticates file integrity after acquisition; it does not authenticate the producer.
- The TLA+ models have not been model-checked in the environment that produced this repository. The exact TLC command is documented so an independent party can perform the check.
- No claim of accreditation, ATO, or compliance certification is made. Control mappings in TRACEABILITY.md are illustrative starting points only.
- The system contains no network code and no language-model component.

---

## Quick Start

Requirements: a C11 compiler. SWI-Prolog (with the `semweb` library) is optional but enables the clearance and conflict tests.

```sh
sh tests/test.sh
```

Manual steps:

```sh
cc -std=c11 -Wall -Wextra -Werror -pedantic -O2 src/ingest.c -o bin/ingest
bin/ingest fixtures/observations.tsv bin/observations.ttl
swipl -q -s src/reason.pl -- bin/observations.ttl 0   # PUBLIC
swipl -q -s src/reason.pl -- bin/observations.ttl 1   # RESTRICTED
sha256sum -c SHA256SUMS
```

Formal checking (when a verified TLA+ distribution is available):

```sh
java -cp /opt/tla/tla2tools.jar tlc2.TLC \
  -config formal/EvidenceGate.cfg formal/EvidenceGate.tla

java -cp /opt/tla/tla2tools.jar tlc2.TLC \
  -config formal/EvidenceGateHyper.cfg formal/EvidenceGateHyper.tla
```

---

## Input Schema

Seven TAB-separated fields, no header:

| Field | Constraints |
|-------|-------------|
| observation_id | Token (ASCII alnum + `_-.`, ≤ 96 chars) |
| asset_id | Token |
| property | Token |
| value | Single line, ≤ 512 bytes, no control characters |
| source_id | Token |
| classification | One of `PUBLIC`, `RESTRICTED`, `SECRET`, `TOP_SECRET` |
| observed_at | Exact lexical form `YYYY-MM-DDTHH:MM:SSZ` |

---

## Formal Guarantees (Current)

The EvidenceGate model states and the Hyper variant checks:

- An evidence identifier cannot be both accepted and rejected.
- A “satisfied” verdict requires admitted evidence whose labels are safe for the control.
- Approval occurs only after a satisfied verdict.
- Publication requires prior approval.
- Publication respects the reader’s clearance.
- When two executions agree on low-labeled evidence, their low-published control sets are identical (observational noninterference via self-composition).

These are abstract obligations. Concrete implementations must still be shown to refine them.

---

## Roadmap (Selected Next Gates)

1. Authenticated identity and mandatory access control (replace command-line clearance with a reference-monitor identity).
2. Integrated SHACL validation in the build.
3. Calendar-valid timestamps (the Awk prototype already sketches this).
4. Entity resolution with ambiguity quarantine.
5. Artifact signing, signed SBOM, and zero-egress build tests.
6. Immutable append-only evidence ledger (Erlang prototype available).
7. Provenance-safe proof objects from the reasoning layer.
8. Distinction between logical contradiction and temporal supersession.
9. Full Generalized Noninterference (∀∃) encoding and additional model families (AirgapTransfer, ProvenanceDAG, MultilevelRelease with declassification, AssessmentWorkflow, Recovery).
10. Adversarial test suite (parser limits, injection, covert channels).

---

## Licensing

This repository is released under the **AIRGAP-KG Research and Demonstration License** (see `LICENSE`).

The license permits free use for non-commercial research, academic study, evaluation, and internal demonstration. Commercial product or service use requires a separate written license from the copyright holders.

Attribution to Ahmad Ali Parr, Jessica Westerhoff, Bel esprit D'accord Trust, and SnapKitty Research Lab must be retained.

---

## Contact and Attribution

- Researchers: Ahmad Ali Parr, Jessica Westerhoff  
- Research owner: Bel esprit D'accord Trust  
- Laboratory: SnapKitty Research Lab  

For commercial licensing or collaboration inquiries, contact the repository maintainers.

---

## Closing

AIRGAP-KG demonstrates that a useful evidence-centric knowledge-graph kernel can be constructed from a few hundred lines of carefully constrained code together with small, checkable formal models. The constraints—complete pre-validation, classification filtering before inference, and independently stated authorization invariants—are chosen so that each can be audited, tested, and, where appropriate, model-checked.

The result is both a working offline prototype and a precise specification of the obligations that any larger system built on the same ideas must discharge.

---

## Detailed Component Reference

### Ingestion Pipeline

The C11 ingest program is intentionally minimal. It uses only the C standard library, fixed-size buffers, and a two-pass strategy:

1. **Validation pass** — Every line is parsed and checked against the schema. Any failure causes immediate rejection with a line number and exit status 3. No output file is created.
2. **Emission pass** — Only after the entire input has been accepted is the Turtle file opened and written.

This eliminates partial-graph attacks. An interrupted process either produces no file or a file that can be rejected by a subsequent integrity check.

Token rules restrict identifiers to a safe subset of ASCII. Classification is a closed enumeration. Timestamps are required to match a single lexical form; calendar validity is left to a later refinement (see the Awk prototype).

### Reasoning Layer

The Prolog program registers the project prefix and defines a numeric mapping from classification IRIs to clearance levels. The core `observation/7` predicate embeds the clearance test in its body. Consequently any rule that wishes to examine an observation must do so through a filtered view. The conflict detector re-uses the same predicate, guaranteeing that conflicts involving invisible observations are never reported.

The accompanying test harness verifies two fixture-specific properties:
- Under PUBLIC clearance the string associated with a RESTRICTED observation does not appear.
- Under RESTRICTED clearance both the restricted observation and the resulting conflict are visible, while the public-only run does not report the conflict.

These checks establish a concrete non-interference witness for the supplied fixture; they are not a general proof.

### Formal Layer

`EvidenceGate.tla` models the essential workflow:

- Accept or reject an evidence item (exactly once).
- Assess a control as satisfied only when supporting evidence exists and is label-safe.
- Approve only after a satisfied verdict.
- Publish only after approval and only when the control label is ≤ the reader’s clearance.

Five invariants capture the safety obligations. The companion hyperproperty module (`EvidenceGateHyper.tla`) runs two copies in lockstep and asserts that agreement on low-labeled evidence implies agreement on the low-published set. This reduces a 2-safety observational noninterference property to an ordinary invariant that TLC can check.

Both models are deliberately small so that exhaustive checking remains feasible. They do not encode the C parser, the Prolog engine, or physical media transfer. Their purpose is to give an implementation-independent statement of the required obligations.

### Integrity and Reproducibility

`SHA256SUMS` records the digests of the source files that constitute a release. A recipient can recompute the digests and confirm that the files have not been altered since the manifest was generated. The manifest does not authenticate the producer; that stronger claim requires a signed toolchain and a software bill of materials—both listed on the roadmap.

---

## Example Walk-Through

The supplied fixture contains four observations:

1. generator_a / status / operational / PUBLIC
2. generator_a / status / maintenance_required / RESTRICTED
3. generator_b / status / operational / PUBLIC
4. generator_a / location / warehouse_2 / PUBLIC

After ingestion the graph contains four Observation resources. Querying at clearance 0 returns only the three PUBLIC observations and reports no conflict. Querying at clearance 1 returns all four observations and reports the status conflict on generator_a. The formal model can be instantiated with a matching pair of evidence items and controls; the invariants guarantee that a reader whose clearance is 1 cannot see a control labeled 3 published.

---

## Assurance Narrative

An assurance argument built on AIRGAP-KG proceeds in layers:

1. **Lexical and structural correctness** — discharged by the C11 pre-validation and the test harness.
2. **Clearance noninterference on the fixture** — discharged by the Prolog tests.
3. **Abstract authorization obligations** — discharged by TLC on EvidenceGate (once a toolchain is present).
4. **Observational noninterference on the low view** — discharged by TLC on the self-composed hyperproperty model.
5. **Refinement to concrete code** — remaining work; the models supply the contracts that the refinement must satisfy.
6. **Supply-chain and operational controls** — outside the present kernel (signed SBOM, zero-egress deployment, authenticated identity, etc.).

Each layer is small enough to be examined independently. The overall claim is therefore the conjunction of these individually checkable pieces rather than a single monolithic proof.

---

## Deployment Considerations

AIRGAP-KG is designed for environments in which the following constraints hold:

- Network interfaces can be disabled or are physically absent.
- All inputs arrive via removable media or other explicitly authorized offline channels.
- The set of tools (C compiler, Prolog interpreter, optional TLA+ distribution) can be obtained through a verified offline process and pinned by hash.
- Operators are prepared to treat the kernel as a reference implementation whose invariants must be preserved by any surrounding system.

In such settings the prototype can serve as the trusted core of a larger evidence-management pipeline. In all other settings it remains a precise specification and a source of regression tests for the properties it already encodes.

---

## Glossary

| Term | Meaning in this repository |
|------|----------------------------|
| Evidence | An observation that has been accepted into the graph |
| Clearance | Numeric level (0–3) supplied to the query layer |
| Low view | The set of observations and published controls visible at a given clearance |
| Observational noninterference | Agreement on low evidence implies agreement on the low-published set |
| Pre-validation | Complete checking of input before any output file is created |
| Self-composition | Technique that reduces a k-safety hyperproperty to an ordinary property on k renamed copies |

---

## Versioning and Stability

The present release is a reference kernel (v0.2 formal extension). Interfaces (TSV schema, Turtle vocabulary, clearance numeric mapping, TLA+ invariant names) are expected to remain stable so that later refinements can be compared against the same fixtures and models. Breaking changes will be versioned and documented.

---

AIRGAP-KG is offered as a clean, auditable foundation for offline evidence-centric knowledge graphs. The combination of a tiny deterministic implementation and independently stated formal models makes both the capabilities and the limits of the system explicit—exactly what is required when the artifact is used for technical evaluation, research, or as the starting point for a larger assured system.
