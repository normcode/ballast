use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :info

import_config "#{Mix.env}.exs"
