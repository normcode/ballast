use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :debug

config :ballast,
  proxy_port: String.to_integer(System.get_env("PORT") || "8080"),
  routes: [
    [path: "/debug", prefix: "/debug", plug: {Ballast.Plug.Proxy, [origin: "httpbin.org"]}],
  ]
