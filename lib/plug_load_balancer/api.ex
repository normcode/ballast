defmodule PlugLoadBalancer.Api do
  use Plug.Router

  plug :fetch_routes
  plug :match
  plug :dispatch

  @behaviour Plug
  @config PlugLoadBalancer.Config

  def child_spec(opts \\ []) do
    port = Keyword.get(opts, :port, 5000)
    scheme    = Keyword.get(opts, :scheme, :http)
    config = Keyword.get(opts, :config, @config)
    plug      = Keyword.get(opts, :plug, PlugLoadBalancer.Api)
    plug_opts =
      opts
      |> Keyword.get(:plug_opts, [])
      |> Keyword.put(:config, config)
    cowboy_opts =
      opts
      |> Keyword.get(:cowboy_opts, [])
      |> Keyword.put(:port, port)
    Plug.Adapters.Cowboy.child_spec(scheme, plug, plug_opts, cowboy_opts)
  end

  def call(conn, opts) do
    config = Keyword.get(opts, :config, @config)
    conn
    |> put_private(:plug_load_balancer_config, config)
    |> super(opts)
  end

  defp fetch_routes(conn, _opts) do
    config = conn.private.plug_load_balancer_config
    routes = @config.routes(config)
    put_private(conn, :routes, routes)
  end

  get "/api/routes" do
    response = inspect(conn.private.routes)
    send_resp(conn, 200, response)
  end
end
