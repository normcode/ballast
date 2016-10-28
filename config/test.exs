use Mix.Config

config :ballast, [routes: [],
                  listener: Test.ProxyEndpoint,
                  proxy_port: 8888,
                  api_port: 5555]
