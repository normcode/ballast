defmodule Ballast.Plug.Debug do
  @behaviour Plug
  import Plug.Conn

  def init(_opts), do: nil
  def call(conn, _opts) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, json(conn))
  end

  def json(conn) do
    response = request_to_map(conn)
    Poison.encode!(response)
  end

  defp request_to_map(conn) do
    %{method: conn.method,
      headers: format_headers(conn.req_headers),
      origin: "",
      url: ""}
  end

  defp format_headers(headers) do
    for h <- headers, do: Tuple.to_list(h)
  end
end
