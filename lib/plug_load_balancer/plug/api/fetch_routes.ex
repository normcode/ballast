defmodule PlugLoadBalancer.Plug.Api.FetchRoutes do
  import Plug.Conn
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, opts) do
    config = opts[:config]
    routes = PlugLoadBalancer.Config.routes(config)
    put_private(conn, :routes, routes)
  end
end
