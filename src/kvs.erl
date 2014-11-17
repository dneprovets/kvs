-module(kvs).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

-include("logger.hrl").

% ключ
-type(key() :: binary() | string() | atom()).
% значение
-type(value() :: term()).
% значение + время
-type(value_time():: {calendar:datetime(), value()}).
% ключ + список
-type(key_set() :: {key(),[value_time()]}).

%Example
%[
%	{key1,[{DT1, val1}, {DT1, val1}, {DT1, val1}]},
%	{key1,[{DT1, val1}, {DT1, val1}, {DT1, val1}]},
%	{key1,[{DT1, val1}, {DT1, val1}, {DT1, val1}]}
% ]

-record(state,{
		items = [] :: [key_set()]
	}).


%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/1, create/2, read/1, update/2, delete/1, clear/0, save_to_file/2]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link(Options) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, Options, []).

-spec(create(key(), value()) -> ok).
create (Key, Value) ->
	gen_server:call(?MODULE, {create, Key, Value}),
	ok.

-spec(read(key()) -> key_set() | {error, not_found}).
read(Key) ->
	gen_server:call(?MODULE, {read, Key}).

-spec(update(key(), value()) -> ok | {error, not_found}).
update(Key, Value) ->
	gen_server:call(?MODULE, {update, Key, Value}).

-spec(delete(key()) -> ok | {error, not_found}).
delete (Key) ->
	gen_server:call(?MODULE, {delete, Key}).

-spec(clear() -> ok).
clear () ->
	gen_server:call(?MODULE, clear),
	ok.

%% ------------------------------------------------------------------a
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(Options) ->
	?INFO("kvs started with options ~p ~n", [Options]),
	FileName = proplists:get_value(date_file, Options),
	FlushInterval = proplists:get_value(flush_interval, Options, 20),
	% self() ! {do_heavy_init, FileName},
	% timer:send_interval(FlushInterval * 1000, self(), 
	% 								{flush, FileName}),
	{ok, #state{}}.

handle_call({create, Key, Value}, _From, #state{items=Items} = State) ->
	DT = {date(), time()},
	case proplists:get_value(Key, Items) of
		undefined -> KeySet = {Key, [{DT, Value}]},
					 NewItems = [KeySet | Items],
					 NewState = State#state{items = NewItems},
					 {reply, ok, NewState};
		Values -> NewValueTime = {DT, Value},
			 NewValues = add_value(NewValueTime, Values),
			 KeySet = {Key, NewValues},
			 NewState = update_state(KeySet, Key, State),
			 {reply, ok, NewState} 
	end;

handle_call({read, Key}, _From, #state{items=Items} = State) ->
	case proplists:get_value(Key, Items) of
		undefined -> {reply, {error, not_found}, State};
		Values ->	KeySet = {Key, Values}, 
				{reply, KeySet, State}
	end;

handle_call({update, Key, Value}, _From, #state{items=Items} = State) ->
	case proplists:get_value(Key, Items) of
		undefined -> {reply, {error, not_found}, State};
		[_FirstVal | Rest] ->	DT = {date(), time()}, 
								NewVal = {DT, Value},
								KeySet = {Key, [NewVal | Rest]},
								NewState = update_state(KeySet, Key, State),
								{reply, ok, NewState} 
	end;	

handle_call({delete, Key}, _From, #state{items=Items} = State) ->
	case proplists:get_value(Key, Items) of
		undefined -> {reply, {error, not_found}, State};
		_ ->	NewItems = proplists:delete(Key, Items), 
				NewState = State#state{items = NewItems},
				{reply, ok, NewState}
	end;


handle_call(clear, _From, State) ->
    {reply, ok, State#state{items = []}};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({do_heavy_init, FileName}, State) ->
	Items = read_from_file(FileName),
	?INFO("kvs inited with items: ~p~n",[Items]),
    {noreply, State#state{items = Items}};

handle_info({flush, FileName}, #state{items=Items} = State) ->
	save_to_file(FileName, Items),
	{noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------
add_value(NewValueTime, [Old1, Old2 | _]) ->
	[NewValueTime, Old1, Old2];
add_value(NewValueTime, Values) ->
	NewValues = [NewValueTime | Values].

update_state(NewKeySet, OldKeySet, #state{items = Items} = State) ->
	Items2 = proplists:delete(OldKeySet, Items),
	Items3 = [NewKeySet | Items2],
	State#state{items= Items3}. 

-spec(save_to_file(string(), [key_set()]) -> ok).
save_to_file (FileName, Items) ->
	Bin = term_to_binary(Items),
	file:write_to_file(FileName, Bin).


-spec(read_from_file(string()) -> [key_set()]).
read_from_file(undefined) ->
		throw("bad_options");
read_from_file(DataFile) ->
	case file:read_file(DataFile) of
		{ok, Data} -> Items = binary_to_term(Data),
						Items;
		_ -> []
	end.  