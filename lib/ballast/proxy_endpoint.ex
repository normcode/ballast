defmodule Ballast.ProxyEndpoint do

  def child_spec(opts \\ []) do
    config    = Keyword.get(opts, :config, Ballast.Config)
    port      = Keyword.get(opts, :port, 8080)
    scheme    = Keyword.get(opts, :scheme, :http)
    routes    = []
    plug_opts = []
    cowboy_opts =
      opts
      |> Keyword.get(:cowboy_opts, [])
      |> Keyword.put_new(:port, port)
      |> Keyword.put_new(:dispatch, routes)
    Plug.Adapters.Cowboy.child_spec(scheme, Ballast.Plug.Proxy, plug_opts, cowboy_opts)
  end

end
