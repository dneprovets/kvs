-define(LOGGER, true).

-ifdef(LOGGER).
-define(INFO(Format, Data), error_logger:info_msg(Format, Data)).
-define(INFO_(Format), error_logger:info_msg(Format)).
-else.
-define(INFO(Format, Data), do_nothing).
-define(INFO_(Format), do_nothing).
-endif.

-define(WARN(Format, Data), error_logger:info_msg(Format, Data)).
-define(WARN_(Format), error_logger:info_msg(Format)).

-define(ERROR(Format, Data), error_logger:error_msg(Format, Data)).
-define(ERROR_(Format), error_logger:error_msg(Format)).
