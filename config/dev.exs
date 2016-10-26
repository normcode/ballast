use Mix.Config

config :ballast, routes: [
   [host: "example.org", plug: {Ballast.Plug.Proxy, [origin: "httpbin.org"]}]
]
