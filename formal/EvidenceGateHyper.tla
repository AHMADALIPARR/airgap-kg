(* Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
 * Research owner: Bel esprit D'accord Trust
 * Lab: SnapKitty Research Lab
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *)

--------------------------- MODULE EvidenceGateHyper ---------------------------
(* Self-composition of EvidenceGate for hyperproperty verification.
   Checks observational noninterference on the published controls:
   two executions that agree on low-labeled evidence and on the reader
   clearance must produce identical published sets for controls whose
   label is <= the clearance.

   This is a 2-safety hyperproperty reduced to an ordinary invariant
   via self-composition (two renamed copies run in lockstep).
 *)

EXTENDS Naturals, FiniteSets, TLC

CONSTANTS Evidence, Controls, EvidenceFor, EvidenceLabel, ControlLabel,
          Clearance, Reader

ASSUME /\ Evidence # {}
       /\ Controls # {}
       /\ EvidenceFor \in [Evidence -> Controls]
       /\ EvidenceLabel \in [Evidence -> 0..3]
       /\ ControlLabel \in [Controls -> 0..3]
       /\ Clearance \in [ {Reader} -> 0..3 ]

(* Two copies of the state *)
VARIABLES accepted1, rejected1, verdict1, approved1, published1
VARIABLES accepted2, rejected2, verdict2, approved2, published2

vars1 == <<accepted1, rejected1, verdict1, approved1, published1>>
vars2 == <<accepted2, rejected2, verdict2, approved2, published2>>
vars  == <<vars1, vars2>>

(* Low evidence = evidence whose label <= Clearance[Reader] *)
LowEvidence == {e \in Evidence : EvidenceLabel[e] <= Clearance[Reader]}

Init ==
  /\ accepted1 = {} /\ rejected1 = {} 
     /\ verdict1 = [c \in Controls |-> "unassessed"]
     /\ approved1 = {} /\ published1 = {}
  /\ accepted2 = {} /\ rejected2 = {}
     /\ verdict2 = [c \in Controls |-> "unassessed"]
     /\ approved2 = {} /\ published2 = {}

(* Actions for copy 1 — identical to original EvidenceGate *)
AcceptEvidence1(e) ==
  /\ e \in Evidence \ (accepted1 \cup rejected1)
  /\ accepted1' = accepted1 \cup {e}
  /\ UNCHANGED <<rejected1, verdict1, approved1, published1, vars2>>

RejectEvidence1(e) ==
  /\ e \in Evidence \ (accepted1 \cup rejected1)
  /\ rejected1' = rejected1 \cup {e}
  /\ UNCHANGED <<accepted1, verdict1, approved1, published1, vars2>>

HasEvidence1(c) == \E e \in accepted1 : EvidenceFor[e] = c
SafeEvidence1(c) == \A e \in accepted1 : EvidenceFor[e] = c =>
                             EvidenceLabel[e] <= ControlLabel[c]

AssessSatisfied1(c) ==
  /\ c \in Controls
  /\ verdict1[c] = "unassessed"
  /\ HasEvidence1(c)
  /\ SafeEvidence1(c)
  /\ verdict1' = [verdict1 EXCEPT ![c] = "satisfied"]
  /\ UNCHANGED <<accepted1, rejected1, approved1, published1, vars2>>

AssessFailed1(c) ==
  /\ c \in Controls
  /\ verdict1[c] = "unassessed"
  /\ verdict1' = [verdict1 EXCEPT ![c] = "not-satisfied"]
  /\ UNCHANGED <<accepted1, rejected1, approved1, published1, vars2>>

Approve1(c) ==
  /\ c \in Controls
  /\ verdict1[c] = "satisfied"
  /\ c \notin approved1
  /\ approved1' = approved1 \cup {c}
  /\ UNCHANGED <<accepted1, rejected1, verdict1, published1, vars2>>

Publish1(c) ==
  /\ c \in approved1 \ published1
  /\ ControlLabel[c] <= Clearance[Reader]
  /\ published1' = published1 \cup {c}
  /\ UNCHANGED <<accepted1, rejected1, verdict1, approved1, vars2>>

(* Actions for copy 2 — symmetric *)
AcceptEvidence2(e) ==
  /\ e \in Evidence \ (accepted2 \cup rejected2)
  /\ accepted2' = accepted2 \cup {e}
  /\ UNCHANGED <<rejected2, verdict2, approved2, published2, vars1>>

RejectEvidence2(e) ==
  /\ e \in Evidence \ (accepted2 \cup rejected2)
  /\ rejected2' = rejected2 \cup {e}
  /\ UNCHANGED <<accepted2, verdict2, approved2, published2, vars1>>

HasEvidence2(c) == \E e \in accepted2 : EvidenceFor[e] = c
SafeEvidence2(c) == \A e \in accepted2 : EvidenceFor[e] = c =>
                             EvidenceLabel[e] <= ControlLabel[c]

AssessSatisfied2(c) ==
  /\ c \in Controls
  /\ verdict2[c] = "unassessed"
  /\ HasEvidence2(c)
  /\ SafeEvidence2(c)
  /\ verdict2' = [verdict2 EXCEPT ![c] = "satisfied"]
  /\ UNCHANGED <<accepted2, rejected2, approved2, published2, vars1>>

AssessFailed2(c) ==
  /\ c \in Controls
  /\ verdict2[c] = "unassessed"
  /\ verdict2' = [verdict2 EXCEPT ![c] = "not-satisfied"]
  /\ UNCHANGED <<accepted2, rejected2, approved2, published2, vars1>>

Approve2(c) ==
  /\ c \in Controls
  /\ verdict2[c] = "satisfied"
  /\ c \notin approved2
  /\ approved2' = approved2 \cup {c}
  /\ UNCHANGED <<accepted2, rejected2, verdict2, published2, vars1>>

Publish2(c) ==
  /\ c \in approved2 \ published2
  /\ ControlLabel[c] <= Clearance[Reader]
  /\ published2' = published2 \cup {c}
  /\ UNCHANGED <<accepted2, rejected2, verdict2, approved2, vars1>>

(* Lockstep next-state: one step of either copy, or both simultaneously
   (the simultaneous case is useful for synchronized low steps) *)
Next ==
  \/ \E e \in Evidence : AcceptEvidence1(e) \/ AcceptEvidence2(e)
  \/ \E e \in Evidence : RejectEvidence1(e) \/ RejectEvidence2(e)
  \/ \E c \in Controls : AssessSatisfied1(c) \/ AssessSatisfied2(c)
  \/ \E c \in Controls : AssessFailed1(c) \/ AssessFailed2(c)
  \/ \E c \in Controls : Approve1(c) \/ Approve2(c)
  \/ \E c \in Controls : Publish1(c) \/ Publish2(c)

Spec == Init /\ [][Next]_vars

(* Low-published controls: those that may be observed by the reader *)
LowPublished1 == {c \in published1 : ControlLabel[c] <= Clearance[Reader]}
LowPublished2 == {c \in published2 : ControlLabel[c] <= Clearance[Reader]}

(* Hyperproperty (reduced to ordinary invariant via self-composition):
   If the two copies have accepted exactly the same low-labeled evidence,
   then their low-published sets must be identical. *)
SameLowEvidence ==
  (accepted1 \cap LowEvidence) = (accepted2 \cap LowEvidence)

ObservationalNoninterference ==
  SameLowEvidence => (LowPublished1 = LowPublished2)

TypeOK ==
  /\ accepted1 \subseteq Evidence /\ rejected1 \subseteq Evidence
  /\ accepted2 \subseteq Evidence /\ rejected2 \subseteq Evidence
  /\ verdict1 \in [Controls -> {"unassessed", "satisfied", "not-satisfied"}]
  /\ verdict2 \in [Controls -> {"unassessed", "satisfied", "not-satisfied"}]
  /\ approved1 \subseteq Controls /\ published1 \subseteq Controls
  /\ approved2 \subseteq Controls /\ published2 \subseteq Controls

=============================================================================
