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
    [path:   "/httpbin", # matches path
     prefix: "/httpbin", # removes path prefix
     plug:   {Proxy, [origin: "httpbin.org"]}], # request is proxied to origin
    [host: "example.org", # matches host header, exactly
     plug:   {Proxy, [origin: "localhost:4000"]}]
  ]
]
```

Start the application within the configured environment:

    $ MIX_ENV=proxy iex -S mix
    $ curl localhost:8080/httpbin/get -i
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
        "Host": "httpbin.org",
        "User-Agent": "curl/7.43.0"
      },
      "origin": "10.0.0.1",
      "url": "http://httpbin.org/get"
    }

The HTTP dispatch rules can be changed at runtime. From the `iex` REPL:

```elixir
iex> Config.update(rules: [[host: "example.com", plug: {SomePlug, []}]])
:ok
```

## Deploying to Heroku ##

Create a configuration file, `config/heroku.exs`:

```elixir
use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :debug

config :ballast, proxy_port: {:system, "PORT"},
                 routes: [
                   [path: "/debug", prefix: "/debug",
                    plug: {Ballast.Plug.Proxy, [origin: "httpbin.org"]}],
                 ]
```

Note that you cannot route using the `Host` header because Heroku uses that as
well for routing to dynos so this is of limited value.

Using the `heroku` CLI, set the buildpack and the remote:

    $ heroku buildpacks:set https://github.com/HashNuke/heroku-buildpack-elixir
    $ heroku git:remote -a twin-miracles-12345

And push to deploy:

    $ git push heroku master

Send a request to the dyno:

    $ curl https://twin-miracles-12345.herokuapp.com -i
    curl https://twin-mircales-12345.herokuapp.com/debug/get -i
    HTTP/1.1 200 OK
    Connection: keep-alive
    Cache-Control: max-age=0, private, must-revalidate
    Access-Control-Allow-Credentials: true
    Access-Control-Allow-Origin: *
    Content-Length: 344
    Content-Type: application/json
    Date: Fri, 03 Mar 2017 23:19:14 GMT
    Server: nginx
    Via: 1.1 ballast, 1.1 vegur

    {
      "args": {},
      "headers": {
        "Accept": "*/*",
        "Connect-Time": "0",
        "Host": "httpbin.org",
        "Total-Route-Time": "0",
        "User-Agent": "curl/7.43.0",
        "Via": "1.1 vegur",
        "X-Request-Id": "cd4666e4-e3ce-458a-ba67-5f97dbbddef5"
      },
      "origin": "76.76.76.76, 54.224.168.123",
      "url": "https://httpbin.org/get"
    }
