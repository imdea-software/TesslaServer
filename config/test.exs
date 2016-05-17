use Mix.Config

config :logger,
  compile_time_purge_level: :warn,
  truncate: 4096

config :ex_unit,
  assert_receive_timeout: 500
