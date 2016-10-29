defmodule Ballast.ProxyEndpoint do
  @behaviour Plug
  import Plug.Conn

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

  def init(opts), do: Keyword.fetch!(opts, :plug)

  def call(conn, _plug = {mod, args}) do
    conn
    |> mod.call(args)
    |> set_via_header()
  end

  defp set_via_header(conn) do
    header = case get_resp_header(conn, "via") do
               [] -> "1.1 ballast"
               [value] -> "1.1 ballast, " <> value
             end
    put_resp_header(conn, "via", header)
  end
end
