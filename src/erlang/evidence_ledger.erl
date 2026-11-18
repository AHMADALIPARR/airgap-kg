%%% Copyright (C) 2026 Ahmad Ali Parr, Jessica Westerhoff
%%% Research owner: Bel esprit D'accord Trust
%%% Lab: SnapKitty Research Lab
%%%
%%% This program is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU Affero General Public License as published
%%% by the Free Software Foundation, either version 3 of the License, or
%%% (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU Affero General Public License for more details.
%%%
%%% You should have received a copy of the GNU Affero General Public License
%%% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%%%
%%% Erlang prototype for next-step #6: Immutable append-only evidence ledger.
%%% Simple gen_server that maintains a hash-chained log of accepted observations.
%%% Each entry stores previous hash + observation tuple; verification walks the chain.

-module(evidence_ledger).
-behaviour(gen_server).

-export([start_link/0, append/1, verify/0, get_log/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {log = [], last_hash = <<0:256>>}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

append(Observation) when is_tuple(Observation) ->
    gen_server:call(?MODULE, {append, Observation}).

verify() ->
    gen_server:call(?MODULE, verify).

get_log() ->
    gen_server:call(?MODULE, get_log).

init([]) ->
    {ok, #state{}}.

handle_call({append, Obs}, _From, #state{log = Log, last_hash = Prev} = State) ->
    Entry = {Prev, Obs, erlang:phash2({Prev, Obs})},
    NewHash = crypto:hash(sha256, term_to_binary(Entry)),
    NewLog = [Entry | Log],
    {reply, {ok, NewHash}, State#state{log = NewLog, last_hash = NewHash}};

handle_call(verify, _From, #state{log = Log} = State) ->
    Result = verify_chain(lists:reverse(Log), <<0:256>>),
    {reply, Result, State};

handle_call(get_log, _From, #state{log = Log} = State) ->
    {reply, lists:reverse(Log), State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

verify_chain([], _Prev) ->
    {ok, valid};
verify_chain([{Prev, Obs, StoredHash} | Rest], ExpectedPrev) ->
    case Prev =:= ExpectedPrev of
        true ->
            Computed = erlang:phash2({Prev, Obs}),
            case Computed =:= StoredHash of
                true ->
                    NewHash = crypto:hash(sha256, term_to_binary({Prev, Obs, StoredHash})),
                    verify_chain(Rest, NewHash);
                false ->
                    {error, hash_mismatch}
            end;
        false ->
            {error, chain_break}
    end.
