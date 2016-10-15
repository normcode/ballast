defmodule PlugLoadBalancer.Plug.ApiRouter do
  use Plug.Router

  plug :match
  plug :dispatch

  @behaviour Plug

  def child_spec(opts \\ []) do
    port   = Keyword.get(opts, :port, 5000)
    scheme = Keyword.get(opts, :scheme, :http)
    plug_opts =
      opts
      |> Keyword.get(:plug_opts, [])
      |> Keyword.put_new(:config, PlugLoadBalancer.Config)
    cowboy_opts =
      opts
      |> Keyword.get(:cowboy_opts, [])
      |> Keyword.put_new(:port, port)
    Plug.Adapters.Cowboy.child_spec(scheme, __MODULE__, plug_opts, cowboy_opts)
  end

  def init(opts) do
    fetch_routes_opts = PlugLoadBalancer.Plug.Api.FetchRoutes.init(opts)
    opts
    |> Keyword.put(:fetch_routes_opts, fetch_routes_opts)
    |> super()
  end

  def call(conn, opts) do
    fetch_routes_opts = Keyword.get(opts, :fetch_routes_opts, nil)
    conn
    |> PlugLoadBalancer.Plug.Api.FetchRoutes.call(fetch_routes_opts)
    |> super(opts)
  end

  get "/api/routes" do
    response = inspect(conn.private.routes)
    send_resp(conn, 200, response)
  end
end
