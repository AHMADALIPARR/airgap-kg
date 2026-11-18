% Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
% Research owner: Bel esprit D'accord Trust
% Lab: SnapKitty Research Lab
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
%
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%

:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/turtle)).
:- use_module(library(lists)).
:- rdf_register_prefix(ex, 'urn:airgap:kg:').

% Always select clearance-eligible assertions BEFORE applying deduction.
level('urn:airgap:kg:PUBLIC', 0).
level('urn:airgap:kg:RESTRICTED', 1).
level('urn:airgap:kg:SECRET', 2).
level('urn:airgap:kg:TOP_SECRET', 3).

observation(Clearance, Obs, Asset, Property, Value, Source, Time) :-
    rdf(Obs, rdf:type, ex:'Observation'),
    rdf(Obs, ex:classification, Label),
    level(Label, Required), Required =< Clearance,
    rdf(Obs, ex:asset, Asset),
    rdf(Obs, ex:property, literal(Property)),
    rdf(Obs, ex:value, literal(Value)),
    rdf(Obs, ex:source, Source),
    rdf(Obs, ex:observedAt, literal(Time)).

% Non-exclusive statuses here are flagged as potentially conflicting,
% NOT automatically declared logically impossible.
conflict(Clearance, Asset, Property, A, B) :-
    observation(Clearance, A, Asset, Property, V1, _, _),
    observation(Clearance, B, Asset, Property, V2, _, _),
    A @< B, V1 \= V2.

print_visible(Clearance) :-
    forall(observation(Clearance, Obs, Asset, Property, Value, Source, Time),
      format('OBS ~q ~q ~q ~q ~q ~q~n', [Obs,Asset,Property,Value,Source,Time])).
print_conflicts(Clearance) :-
    forall(conflict(Clearance, Asset, Property, A, B),
      format('CONFLICT ~q ~q ~q ~q~n', [Asset,Property,A,B])).

main :-
    current_prolog_flag(argv, Args),
    ( Args=[Path, LevelText], atom_number(LevelText, Clearance),
      integer(Clearance), between(0,3,Clearance) -> true
    ; format(user_error, 'usage: swipl -q -s src/reason.pl -- GRAPH.ttl CLEARANCE_0_TO_3~n', []), halt(2)),
    rdf_load(Path, [format(turtle), imports(false)]),
    print_visible(Clearance), print_conflicts(Clearance), halt(0).
:- initialization(main, main).
