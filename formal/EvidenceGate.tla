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

--------------------------- MODULE EvidenceGate ---------------------------
EXTENDS Naturals, FiniteSets, TLC

CONSTANTS Evidence, Controls, EvidenceFor, EvidenceLabel, ControlLabel,
          Clearance, Reader

ASSUME /\ Evidence # {}
       /\ Controls # {}
       /\ EvidenceFor \in [Evidence -> Controls]
       /\ EvidenceLabel \in [Evidence -> 0..3]
       /\ ControlLabel \in [Controls -> 0..3]
       /\ Clearance \in [ {Reader} -> 0..3 ]

VARIABLES accepted, rejected, verdict, approved, published
vars == <<accepted, rejected, verdict, approved, published>>

Init == /\ accepted = {}
        /\ rejected = {}
        /\ verdict = [c \in Controls |-> "unassessed"]
        /\ approved = {}
        /\ published = {}

AcceptEvidence(e) ==
  /\ e \in Evidence \ (accepted \cup rejected)
  /\ accepted' = accepted \cup {e}
  /\ UNCHANGED <<rejected, verdict, approved, published>>

RejectEvidence(e) ==
  /\ e \in Evidence \ (accepted \cup rejected)
  /\ rejected' = rejected \cup {e}
  /\ UNCHANGED <<accepted, verdict, approved, published>>

HasEvidence(c) == \E e \in accepted : EvidenceFor[e] = c
SafeEvidence(c) == \A e \in accepted : EvidenceFor[e] = c =>
                            EvidenceLabel[e] <= ControlLabel[c]

AssessSatisfied(c) ==
  /\ c \in Controls
  /\ verdict[c] = "unassessed"
  /\ HasEvidence(c)
  /\ SafeEvidence(c)
  /\ verdict' = [verdict EXCEPT ![c] = "satisfied"]
  /\ UNCHANGED <<accepted, rejected, approved, published>>

AssessFailed(c) ==
  /\ c \in Controls
  /\ verdict[c] = "unassessed"
  /\ verdict' = [verdict EXCEPT ![c] = "not-satisfied"]
  /\ UNCHANGED <<accepted, rejected, approved, published>>

Approve(c) ==
  /\ c \in Controls
  /\ verdict[c] = "satisfied"
  /\ c \notin approved
  /\ approved' = approved \cup {c}
  /\ UNCHANGED <<accepted, rejected, verdict, published>>

Publish(c) ==
  /\ c \in approved \ published
  /\ ControlLabel[c] <= Clearance[Reader]
  /\ published' = published \cup {c}
  /\ UNCHANGED <<accepted, rejected, verdict, approved>>

Next == \/ \E e \in Evidence : AcceptEvidence(e)
        \/ \E e \in Evidence : RejectEvidence(e)
        \/ \E c \in Controls : AssessSatisfied(c)
        \/ \E c \in Controls : AssessFailed(c)
        \/ \E c \in Controls : Approve(c)
        \/ \E c \in Controls : Publish(c)

Spec == Init /\ [][Next]_vars

TypeOK == /\ accepted \subseteq Evidence
          /\ rejected \subseteq Evidence
          /\ verdict \in [Controls -> {"unassessed", "satisfied", "not-satisfied"}]
          /\ approved \subseteq Controls
          /\ published \subseteq Controls

NoEvidenceConflict == accepted \cap rejected = {}
NoUnsupportedVerdict == \A c \in Controls : verdict[c] = "satisfied" =>
  (HasEvidence(c) /\ SafeEvidence(c))
NoUnapprovedRelease == published \subseteq approved
NoUnauthorizedRelease == \A c \in published : ControlLabel[c] <= Clearance[Reader]
NoFalseApproval == \A c \in approved : verdict[c] = "satisfied"

=============================================================================
