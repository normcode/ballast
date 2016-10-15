defmodule PlugLoadBalancer.Plug.Default do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts
  def call(conn, _opts) do
    send_resp(conn, 200, "ok")
  end
end
