-module(http_api_handler).

-behaviour(cowboy_http_handler).
 
-export([init/3]).
-export([handle/2]).
-export([terminate/3]).
 
-include("logger.hrl").

init({tcp, http}, Req, Opts) ->
    {ok, Req, undefined_state}.
 
handle(Req, State) ->
	{Url, _} = cowboy_req:url(Req),
    {HostUrl, _} = cowboy_req:host_url(Req),
    Params = lists:subtract(binary_to_list(Url), binary_to_list(HostUrl)),
    [Action | _Tokens] = string:tokens(Params, "/"),

    {Key, Req2} = cowboy_req:qs_val(<<"key">>, Req, <<>>),
    {Value, Req3} = cowboy_req:qs_val(<<"value">>, Req2, <<>>),

    R = process_query(Action, Key, Value),
    Reply = io_lib:format("~p~n",[R]),

    {ok, Req4} = cowboy_req:reply(200, [], list_to_binary(Reply), Req3),
    {ok, Req4, State}.
 
terminate(Reason, Req, State) ->
    ok.


process_query(_, <<>>, _) ->
	"error, inavlid key";

process_query("create", Key, Value) -> 
	kvs:create(Key, Value);

process_query("read", Key, _) -> 
	kvs:read(Key);

process_query("update", Key, Value) -> 
	kvs:update(Key, Value);

process_query("delete", Key, _) ->
	kvs:delete(Key);

process_query("clear", _, _) ->
	kvs:clear();

process_query(_Any, Key, Value) ->
	"error, inavlid key".