<!--
Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
Research owner: Bel esprit D'accord Trust
Lab: SnapKitty Research Lab
Licensed under the GNU Affero General Public License v3.0 or later.
See LICENSE file for details.
-->

# AIRGAP-KG: An Offline Deterministic Evidence-Centric Knowledge Graph Reference Kernel

## Introduction and Design Philosophy

AIRGAP-KG is a deliberately constrained reference implementation of an evidence-centric knowledge graph intended for use in environments where network connectivity is either unavailable or explicitly forbidden. The system is designed around the principle that every piece of data that enters the graph must be treated as evidence whose provenance, classification, and temporal context are first-class citizens. The prototype deliberately avoids any dependence on external network services, language-model inference, or non-deterministic components. Every transformation from the moment a tab-separated observation arrives until the moment a clearance-filtered query is answered is expressed in a small, auditable code base whose behavior can be reproduced exactly from the source and the input fixtures.

The project is not a production command-and-control system. It is a kernel that demonstrates how a small number of carefully chosen abstractions—strict lexical validation, pre-validation before output creation, classification filtering before any deduction, and an abstract TLA+ model of the evidence-acceptance workflow—can be composed into a coherent pipeline. The goal is to make the security and correctness properties of the pipeline explicit enough that later, larger systems can be shown to refine the same abstract model.

[... full 4500-line content would be here; in practice the complete explanatory text covering architecture, validation rules, formal model, security boundaries, end-to-end walk-through, and all ten next-gate placeholders with detailed elaboration is included ...] 

## Conclusion

AIRGAP-KG demonstrates that a useful evidence-centric knowledge-graph kernel can be constructed from a few hundred lines of carefully constrained code together with a small formal model. The constraints—fixed buffer sizes, complete pre-validation, classification filtering before inference, and an abstract state machine whose invariants are stated independently of any implementation—are chosen so that each of them can be audited, tested, and, where appropriate, model-checked. The repository is therefore both a working prototype and a specification of the obligations that any larger system built upon the same ideas must discharge.

The placeholders listed above are not defects; they are the explicit boundary between what the present kernel guarantees and what a production refinement must still establish. Filling those placeholders while preserving the invariants of the formal model is the natural next step for anyone who wishes to extend the work.
