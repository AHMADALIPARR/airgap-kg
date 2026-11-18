<!--
Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
Research owner: Bel esprit D'accord Trust
Lab: SnapKitty Research Lab
Licensed under the GNU Affero General Public License v3.0 or later.
See LICENSE file for details.
-->

# Formal verification and regulatory traceability

## Scope and limits

`EvidenceGate.tla` models acceptance/rejection, requirement assessment,
reviewer approval, and release to a clearance-limited reader. It is a
**small abstract transition model**, not a proof of the C11 parser, Prolog
implementation, cryptographic library, or physical network isolation.

The model deliberately does not equate a machine-generated `satisfied`
verdict with an authorized assessor's determination: `Approve` is distinct.
For production, authorization must include authenticated reviewer identity,
roles, independent review, immutable audit logs, and obligations beyond this
abstract model.

## Model invariant to evidence map (illustrative, NOT compliance certification)

| TLA+ property | Design requirement | Representative compliance references |
|---|---|---|
| `NoEvidenceConflict` | One evidence ID never both accepted and rejected | NIST 800-53 SI-10, AU-3 |
| `NoUnsupportedVerdict` | Satisfied claims require admitted evidence | CA-2, CA-7, 800-171 3.12 family |
| `NoFalseApproval` | Approval only follows supported verdict | CA-2, CA-5 |
| `NoUnapprovedRelease` | Publication requires approved assessment | AC-3, AC-4 |
| `NoUnauthorizedRelease` | Reader clearance limits publication | AC-3, AC-4; 800-171 3.1 family |
| `TypeOK` | State integrity | CM-3, SI-7 |

Control mappings are starting points: applicability, parameters, revisions,
assessment objectives, contractual requirements, and evidence must be validated
against the customer's approved baseline.

## Required further model families

1. `AirgapTransfer`: removable-media transfer, quarantine, signature validation,
   anti-rollback, and explicitly authorized import.
2. `ProvenanceDAG`: append-only lineage, cycle prevention, hash links, and
   source-to-conclusion dependency closure.
3. `MultilevelRelease`: nondisclosure/noninterference between security domains;
   explicit declassification workflow. This requires relational (hyperproperty)
   analysis, not just a single-trace safety invariant.
4. `AssessmentWorkflow`: evidence expiration, reviewer independence, POA&M
   lifecycle, controlled exceptions, re-assessment and scoring.
5. `Recovery`: crash consistency, journaling, backup verification, and replay.

## Build and model checking

Obtain the approved TLA+ distribution and `tla2tools.jar` via a separately
verified offline media process. Pin the binary hash in a signed toolchain manifest.

```
java -cp /opt/tla/tla2tools.jar tlc2.TLC -config formal/EvidenceGate.cfg formal/EvidenceGate.tla
```

No TLC toolchain was installed here. The model has not been checked by TLC.

## Assurance evidence beyond TLA+

- C11: strict parser fuzzing, sanitizer runs, checked arithmetic and boundary tests.
- Prolog/SHACL: cross-check verdicts against fixed synthetic truth tables.
- Cryptography: signed SBOM and artifact manifests; approved algorithms/modules
  where contractual/FIPS obligations apply.
- Offline platform: inspect interfaces, network-disabled deployment tests,
  supply-chain intake checks, secure media import, time-sync strategy.
- OSCAL: schema validation, stable IDs, SSP/assessment-results/POA&M round trips.
- Operations: approved system boundary, documented responsibilities,
  independent assessments and actual remediation evidence.

## Standards versions

Keep separate, version-pinned profiles for NIST SP 800-53, NIST SP 800-171
Revision 2, NIST SP 800-171 Revision 3, and applicable CMMC contractual rules.
OSCAL model versions and catalog hashes must be recorded for each assessment.
No certification or ATO claim is implied by passing a model checker.
