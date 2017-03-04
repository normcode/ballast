use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :debug

config :ballast,
  proxy_port: System.get_env("PORT"),
  routes: [
    [path: "/debug", prefix: "/debug", plug: {Ballast.Plug.Proxy, [origin: "httpbin.org"]}],
  ]
