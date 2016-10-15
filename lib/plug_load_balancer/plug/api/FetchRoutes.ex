defmodule PlugLoadBalancer.Plug.Api.FetchRoutes do
  import Plug.Conn
  @behaviour Plug

  def init(opts) do
    Keyword.get(opts, :config, PlugLoadBalancer.Config)
  end

  def call(conn, config) do
    routes = PlugLoadBalancer.Config.routes(config)
    put_private(conn, :routes, routes)
  end
end
