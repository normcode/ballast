use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :debug

config :ballast, routes: [
  [host: "httpbin.org", plug: {Ballast.Plug.Proxy, [origin: "httpbin.org"]}],
  [path: "/debug", prefix: "/debug", plug: {Ballast.Plug.Proxy, [origin: "localhost:4000"]}],
]
