defmodule Ballast.ClientTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  alias Ballast.Client

  setup [:bypass, :client]

  defp bypass(_ctx) do
    {:ok, [bypass: Bypass.open]}
  end

  defp client(_ctx = %{bypass: origin}) do
    bypass_client = Client.build(origin: "http://localhost:#{origin.port}")
    {:ok, [client: bypass_client]}
  end

  test "uses origin as base url", ctx = %{bypass: origin, client: client} do
    expect_request(ctx, "GET", "/get", "", "")
    response = Client.request(client, method: :get, url: "/get")
    assert response.url == "http://localhost:#{origin.port}/get"
  end

  test "passes GET params", ctx = %{client: client} do
    expect_request(ctx, "GET", "/get", "foo=bar&foo=baz", "")
    query_params = [{"foo", "bar"}, {"foo", "baz"}]
    Client.request(client, [method: :get,
                            url: "/get",
                            query: query_params])
  end

  test "passes POST body", ctx = %{client: client} do
    expect_request(ctx, "POST", "/post", "", "post data")
    request = [method: :post,
               url: "/post",
               body: "post data"]
    Client.request(client, request)
  end

  test "sends OPTIONS request", ctx = %{client: client} do
    expect_request(ctx, "OPTIONS", "/", "", "")
    request = [method: "OPTIONS",
               url: "/"]
    Client.request(client, request)
  end

  test "sends undefined method", ctx = %{client: client} do
    expect_request(ctx, "TEST", "/", "", "")
    request = [method: "TEST",
               url: "/"]
    Client.request(client, request)
  end

  test "sends headers", _ctx = %{bypass: origin, client: client} do
    Bypass.expect(origin, fn conn ->
      assert Enum.sort(conn.req_headers) == [{"foo", "Baz"},
                                             {"host", "localhost:#{origin.port}"},
                                             {"user-agent", "ballast/1.0.0"},
                                             # cannot disable default u-a with hackney so
                                             # set a default
                                            ]
    end)
    request = [method: :get,
               url: "/",
               headers: [{"Foo", "Baz"}]]
    Client.request(client, request)
  end

  defp expect_request(ctx, method, request_path, query_string, body) do
    Bypass.expect(ctx.bypass, fn conn ->
      assert conn.method == method
      assert conn.request_path == request_path
      assert conn.query_string == query_string
      {:ok, req_body, conn} = Plug.Conn.read_body(conn)
      assert req_body == body
      send_resp(conn, 200, "")
    end)
  end

end
