# Ballast

An HTTP reverse proxy and load balancer.

## Usage ##

Install and build the application and dependencies:

    $ git clone git@github.com:normcode/ballast.git
    $ cd ballast
    $ mix deps.get
    Running dependency resolution
    ...
    $ mix compile
    ...

Create a configuration file, `./config/proxy.exs`:

```elixir
use Mix.Config
alias Ballast.Plug.Proxy

config :ballast, [
  proxy_port: 8080,
  routes: [
    [path: "/httpbin", prefix: "/httpbin",    # matches and removes URI prefix
     plug: {Proxy, [origin: "httpbin.org"]}],
    [host: "example.com",                     # matches HTTP `host` header
     plug: {Proxy, [origin: "127.0.0.1:4000"]}]
  ]
]
```

Start the application within the configured environment:

    $ MIX_ENV=proxy iex -S mix
    $ curl -H "Host: example.com" "localhost:8080/get -i
    HTTP/1.1 200 OK
    cache-control: max-age=0, private, must-revalidate
    access-control-allow-credentials: true
    access-control-allow-origin: *
    connection: keep-alive
    content-length: 209
    content-type: application/json
    date: Mon, 31 Oct 2016 04:55:46 GMT
    server: nginx
    via: 1.1 ballast

    {
      "args": {},
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "example.org",
        "User-Agent": "curl/7.43.0"
      },
      "origin": "10.0.0.1",
      "url": "http://localhost/get"
    }

The HTTP dispatch rules can be changed at runtime. From the `iex` REPL:

```elixir
iex> Config.update(rules: [[host: "example.com", plug: {SomePlug, []}]])
:ok
```
