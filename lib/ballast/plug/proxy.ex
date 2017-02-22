defmodule Ballast.Plug.Proxy do

  import Plug.Conn, only: [assign: 3,
                           merge_resp_headers: 2,
                           resp: 3,
                           read_body: 1]

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
    client = Ballast.Client.build(opts)
    opts = Keyword.put_new(opts, :client, client)
    struct!(__MODULE__, opts)
  end

  defp read_request_body(conn, _opts) do
    {:ok, body, conn} = read_body(conn)
    assign(conn, :body, body)
  end

  defp create_request(conn, _opts) do
    request = [
      method: conn.method,
      url: maybe_append_query_string(conn),
      headers: conn.req_headers,
      body: conn.assigns.body
    ]
    assign(conn, :request, request)
  end

  defp send_request(conn, opts = %__MODULE__{}) do
    try do
      response = Ballast.Client.request(opts.client, conn.assigns.request)
      {:ok, conn, response}
    rescue
      error in [Tesla.Error] ->
        {:error, conn, error}
    end
  end

  defp send_response({:ok, conn = %Plug.Conn{}, resp}, _opts) do
    conn
    |> merge_resp_headers(resp.headers)
    |> resp(resp.status, resp.body)
  end

  defp send_response({:error, conn = %Plug.Conn{}, error}, _opts) do
    resp_error(conn, error)
  end

  defp resp_error(conn, %{reason: :timeout}) do
    resp(conn, 504, "")
  end

  defp resp_error(conn, %{reason: reason})
  when reason in [:connect_timeout, :econnrefused] do
    resp(conn, 503, "")
  end

  defp resp_error(conn, %{message: message}) do
    require Logger
    Logger.error("Unexpected upstream error: #{message}")
    resp(conn, 500, "")
  end

  defp maybe_append_query_string(conn = %Plug.Conn{query_string: ""}) do
    conn.request_path
  end
  defp maybe_append_query_string(conn = %Plug.Conn{}) do
    conn.request_path <> "?" <> conn.query_string
  end

end
