<!--
Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
Research owner: Bel esprit D'accord Trust
Laboratory: SnapKitty Research Lab
Licensed under the AIRGAP-KG Research and Demonstration License.
See LICENSE file for full terms.
-->

# AIRGAP-KG

![AIRGAP-KG Logo](docs/logo-small.png)

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
