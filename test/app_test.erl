-module(app_test).

-export([all/0]).
-include_lib("eunit/include/eunit.hrl").

all() ->
	case application:get_env(kvs, mode) of
		{ok, test} -> do_nothing;
		{ok, Mode} -> throw ("can't run test in prod mode " ++ atom_to_list(Mode))	
	end,
	kvs_create_read_test(),
	kvs_update_test(),
	kvs_delete_test(),
	ok.


kvs_create_read_test() ->
	kvs:clear(),
	kvs:create(key1, 22),
	?assertMatch({key1, [{_, 22}]}, kvs:read(key1)),
	kvs:create(key1, 23),
	?assertMatch({key1, [{_, 23}, {_, 22}]}, kvs:read(key1)),
	kvs:create(key1, 24),
	?assertMatch({key1, [{_, 24}, {_, 23}, {_, 22}]}, kvs:read(key1)),
	kvs:create(key1, 25),
	?assertMatch({key1, [{_, 25}, {_, 24}, {_, 23}]}, kvs:read(key1)),

	?assertEqual({error, not_found}, kvs:read(key2)),
	kvs:create(key2, 33),
	kvs:create(key2, 34),
	
	?assertMatch({key2, [{_, 34}, {_, 33}]}, kvs:read(key2)),
	kvs:clear(),
	ok.

kvs_update_test() ->
	kvs:clear(),
	?assertEqual({error, not_found}, kvs:update(key1, 11)),
	kvs:create(key1, 22),
	?assertMatch({key1, [{_, 22}]}, kvs:read(key1)),
	kvs:update(key1, 33),
	?assertMatch({key1, [{_, 33}]}, kvs:read(key1)),

	kvs:create(key2, 11),
	kvs:create(key2, 12),
	?assertMatch({key2, [{_, 12},{_, 11}]}, kvs:read(key2)),
	?assertEqual(ok, kvs:update(key2, 15)),
	?assertMatch({key2, [{_, 15},{_, 11}]}, kvs:read(key2)),
	kvs:clear(),
	ok.


kvs_delete_test() ->
	kvs:clear(),
	?assertEqual({error, not_found}, kvs:delete(key1)),
	kvs:create(key1, 11),
	?assertMatch({key1, [{_, 11}]}, kvs:read(key1)),
	?assertEqual(ok, kvs:delete(key1)),
	?assertEqual({error, not_found}, kvs:delete(key1)),
	kvs:clear(),
	ok.