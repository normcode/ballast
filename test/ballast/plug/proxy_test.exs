defmodule Ballast.Plug.ProxyTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ballast.Plug.Proxy

  describe "Ballast.Plug.Proxy" do
    setup [:bypass, :origin, :plug]

    test "proxies to origin", %{bypass: bypass, plug: proxy} do
      Bypass.expect(bypass, fn conn ->
        assert conn.method == "GET"
        send_resp(conn, 200, "")
      end)
      call_proxy(proxy)
    end

    test "sets state (ie does not send response)", ctx do
      mock_response(ctx)
      conn = call_proxy(ctx.plug)
      assert conn.state == :set
    end

    test "sets state on econnrefused", ctx do
      Bypass.down(ctx.bypass)
      conn = call_proxy(ctx.plug)
      assert conn.status == 503
      assert conn.state == :set
    end

    defmodule TimeoutClient do
      def request(_, _, _) do
        %HTTPotion.ErrorResponse{message: "req_timedout"}
      end

    end

    test "sets state on req_timedout", ctx do
      plug = Proxy.init([origin: ctx.origin,
                         http_client: TimeoutClient ])
      conn = call_proxy(plug)
      assert conn.status == 504
      assert conn.state == :set
    end

    test "proxies POST to origin", %{bypass: bypass, plug: proxy} do
      Bypass.expect(bypass, fn conn ->
        assert conn.method == "POST"
        Plug.Conn.send_resp(conn, 200, "")
      end)
      call_proxy(proxy, method: :post)
    end

    test "proxies path", %{bypass: bypass, plug: proxy} do
      Bypass.expect(bypass, fn conn ->
        assert conn.request_path == "/test"
        Plug.Conn.send_resp(conn, 200, "")
      end)
      call_proxy(proxy, path: "/test")
    end

    test "returns status", %{bypass: bypass, plug: proxy} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.send_resp(conn, 201, "")
      end)
      conn = call_proxy(proxy)
      assert conn.status == 201
    end
  end

  defp call_proxy(plug, opts \\ []) do
    host   = Keyword.get(opts, :get, "example.org")
    method = Keyword.get(opts, :method, :get)
    path   = Keyword.get(opts, :path, "/")
    method
    |> conn(path)
    |> Map.put(:host, host)
    |> Proxy.call(plug)
  end

  defp bypass(_ctx) do
    plug = Bypass.open
    [bypass: plug]
  end

  defp mock_response(ctx) do
    Bypass.expect(ctx.bypass, fn conn ->
      Plug.Conn.send_resp(conn, 418, "")
    end)
  end

  defp origin(%{bypass: bypass}) do
    [origin: "localhost:#{bypass.port}"]
  end

  defp plug(%{origin: origin}) do
    [plug: Proxy.init(origin: origin)]
  end
end
