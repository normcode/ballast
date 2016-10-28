defmodule Ballast.ProxyEndpoint do

  def child_spec(opts \\ []) do
    port         = Keyword.get(opts, :port, 8080)
    scheme       = Keyword.get(opts, :scheme, :http)
    listener_ref = Keyword.get(opts, :listener, Ballast.ProxyEndpoint)
    routes       = []
    plug_opts    = []
    cowboy_opts  =
      opts
      |> Keyword.get(:cowboy_opts, [])
      |> Keyword.put_new(:port, port)
      |> Keyword.put_new(:dispatch, routes)
    Plug.Adapters.Cowboy.child_spec(scheme, listener_ref, plug_opts, cowboy_opts)
  end

end
