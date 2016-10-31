use Mix.Config

config :ballast, routes: [
  [host: "example.org", path: "/prefix/get", prefix: "/prefix", plug: {Ballast.Plug.Proxy, [origin: "localhost:4000"]}],
  [host: "example.org", plug: {Ballast.Plug.Proxy, [origin: "localhost:4000"]}],
  [host: "httpbin.org", plug: {Ballast.Plug.Proxy, [origin: "httpbin.org"]}],
]
