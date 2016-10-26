defmodule Ballast.Plug.Proxy do
  import Plug.Conn

  defstruct [:origin]

  @default_timeout 5_000 # in ms

  def init(opts) do
    opts
    |> validate_options!()
    |> initialize_options()
  end

  def call(conn, opts = %__MODULE__{}) do
    conn
    |> read_request_body(opts)
    |> send_request(opts)
    |> send_response(opts)
  end

  defp validate_options!(opts) do
    _ = Keyword.fetch!(opts, :origin)
    opts
  end

  defp initialize_options(opts) do
    struct(__MODULE__, opts)
  end

  defp read_request_body(conn, _opts) do
    {:ok, body, conn} = read_body(conn)
    assign(conn, :body, body)
  end

  defp send_request(conn, opts = %__MODULE__{}) do
    response = HTTPotion.request(
      request_method(conn.method),
      uri(conn, opts.origin),
      headers: request_headers(conn),
      body: conn.assigns.body,
      ibrowse: [host_header: to_char_list(conn.host)],
      timeout: @default_timeout
    )
    assign(conn, :response, response)
  end

  defp send_response(conn = %Plug.Conn{}, _opts) do
    case conn.assigns.response do
      %HTTPotion.Response{body: body, status_code: status, headers: headers} ->
        resp_headers = Enum.into(headers.hdrs, [], &convert_header/1)
        %{conn | resp_headers: resp_headers}
        |> send_resp(status, body)
      %HTTPotion.ErrorResponse{message: "econnrefused"} ->
        send_resp(conn, 503, "")
      %HTTPotion.ErrorResponse{message: "req_timedout"} ->
        send_resp(conn, 504, "")
    end
  end

  defp convert_header({header, value}) do
    {to_string(header), to_string(value)}
  end

  defp uri(conn, origin) do
    case conn.query_string do
      "" ->
        "http://#{origin}#{conn.request_path}"
      query_string ->
        "http://#{origin}#{conn.request_path}?#{query_string}"
    end
  end

  defp request_headers(%Plug.Conn{req_headers: headers}) do
    Enum.filter(headers, &(elem(&1, 0) != "host"))
  end

  @methods ["GET", "HEAD", "POST", "PUT", "DELETE",
            "CONNECT", "OPTIONS", "TRACE", "PATCH"]

  for method <- @methods do
    defp request_method(unquote(method)) do
      unquote(method |> String.downcase() |> String.to_atom())
    end
  end
end
