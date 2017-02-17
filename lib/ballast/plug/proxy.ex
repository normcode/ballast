defmodule Ballast.Plug.Proxy do
  require Logger
  import Plug.Conn

  defstruct [:origin, :client]

  def init(opts) do
    opts
    |> validate_options!()
    |> initialize_options()
  end

  def call(conn, opts = %__MODULE__{}) do
    conn
    |> read_request_body(opts)
    |> create_request(opts)
    |> send_request(opts)
    |> send_response(opts)
  end

  defp validate_options!(opts) do
    _ = Keyword.fetch!(opts, :origin)
    opts
  end

  defp initialize_options(opts) do
    opts = Keyword.put_new(opts, :client, Ballast.Client.build(opts))
    struct!(__MODULE__, opts)
  end

  defp read_request_body(conn, _opts) do
    {:ok, body, conn} = read_body(conn)
    assign(conn, :body, body)
  end

  defp create_request(conn, _opts) do
    conn
    |> fetch_query_params()
    |> create_request()
  end

  defp create_request(conn) do
    request = [
      method: request_method(conn),
      url: conn.request_path,
      query: conn.query_params,
      headers: conn.req_headers,
      body: conn.assigns.body
    ]
    assign(conn, :request, request)
  end

  defp send_request(conn, opts = %__MODULE__{}) do
    try do
      response = Ballast.Client.request(opts.client, conn.assigns.request)
      assign(conn, :response, response)
    rescue
      error in Tesla.Error ->
        assign(conn, :error, error)
    end
  end

  defp send_response(conn = %Plug.Conn{}, _opts) do
    cond do
      error = conn.assigns[:error] ->
        send_error(conn, error)
      resp = conn.assigns[:response] ->
        conn
        |> merge_resp_headers(resp.headers)
        |> resp(resp.status, resp.body)
    end
  end

  defp send_error(conn, %{reason: :timeout}) do
    resp(conn, 504, "")
  end
  defp send_error(conn, %{reason: :econnrefused}) do
    resp(conn, 503, "")
  end
  defp send_error(conn, %{message: message}) do
    Logger.error("Unexpected upstream error: #{message}")
    resp(conn, 500, "")
  end

  @methods ["GET", "HEAD", "POST", "PUT", "DELETE",
            "CONNECT", "OPTIONS", "TRACE", "PATCH"]

  for method <- @methods do
    defp normalize_method(unquote(method)) do
      unquote(method |> String.downcase() |> String.to_atom())
    end
  end

  defp request_method(conn), do: normalize_method(conn.method)
end
