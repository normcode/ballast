defmodule PlugLoadBalancer.Plug.ProxyTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PlugLoadBalancer.Plug.Proxy

  describe "PlugLoadBalancer.Plug.Proxy" do
    setup [:bypass, :origin, :plug]

    test "proxies to origin", %{bypass: bypass, plug: proxy} do
      Bypass.expect(bypass, fn conn ->
        assert conn.method == "GET"
        Plug.Conn.resp(conn, 200, "")
      end)
      call_proxy(proxy)
    end

    test "proxies POST to origin", %{bypass: bypass, plug: proxy} do
      Bypass.expect(bypass, fn conn ->
        assert conn.method == "POST"
        Plug.Conn.resp(conn, 200, "")
      end)
      call_proxy(proxy, method: :post)
    end

    test "proxies path", %{bypass: bypass, plug: proxy} do
      Bypass.expect(bypass, fn conn ->
        assert conn.request_path == "/test"
        Plug.Conn.resp(conn, 200, "")
      end)
      call_proxy(proxy, path: "/test")
    end

    test "returns status", %{bypass: bypass, plug: proxy} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 201, "")
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
    [bypass: Bypass.open]
  end

  defp origin(%{bypass: bypass}) do
    [origin: "localhost:#{bypass.port}"]
  end

  defp plug(%{origin: origin}) do
    [plug: Proxy.init(origin: origin)]
  end
end
