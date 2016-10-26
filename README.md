# Ballast

An HTTP reverse proxy and load balancer.

## Usage ##

Install and build the application and dependencies:

```
$ git clone git@github.com:normcode/ballast.git
$ cd ballast
$ mix deps.get
Running dependency resolution
...
$ mix compile
```

Create a configuration file, `./config/proxy.exs`:

```elixir
use Mix.Config

config :ballast, routes: [
  [host: "example.org", plug: {Proxy, [origin: "httpbin.org"]}]
]
```

... and start the application within the configured environment.

```
$ MIX_ENV=proxy iex -S mix
$ curl -H 'host: example.org' localhost:8080/get -i
HTTP/1.1 200 OK
...
```
