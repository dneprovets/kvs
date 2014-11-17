-module(kvs_app).
-author('Yura Zhloba <yzh44yzh@gmail.com>').

-behaviour(application).
-export([start/0, start/2, stop/1]).
-include("logger.hrl").

start() ->
	ok = application:start(crypto),
	ok = application:start(ranch),
	ok = application:start(cowboy),
    ok = application:start(kvs),
    ok.

start(_StartType, _StartArgs) ->
	{ok, Mode} = application:get_env(mode),
	{ok, Options} = application:get_env(Mode),
	?INFO("application kvs started with settings: ~p~n",[Options]),

	Dispatch = cowboy_router:compile([
	    %% {URIHost, list({URIPath, Handler, Opts})}
	    {'_', [{'_', http_api_handler, []}]}
	]),
	%% Name, NbAcceptors, TransOpts, ProtoOpts
	cowboy:start_http(http_api_handler, 100,
	    [{port, 8989}],
	    [{env, [{dispatch, Dispatch}]}]
	),

    kvs_sup:start_link(Options).

stop(_State) ->
	ok = application:stop(cowboy),
	ok = application:stop(ranch),
	ok = application:stop(crypto),
    ok.
