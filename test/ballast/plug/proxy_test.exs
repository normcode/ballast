defmodule Ballast.Plug.ProxyTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ballast.Plug.Proxy

  describe "Ballast.Plug.Proxy" do
    setup [:bypass, :origin, :plug]

    test "proxies to origin", ctx do
      Bypass.expect(ctx.bypass, fn conn ->
        assert conn.method == "GET"
        send_resp(conn, 200, "")
      end)
      call_proxy(ctx)
    end

    test "sets state (ie does not send response)", ctx do
      mock_response(ctx)
      conn = call_proxy(ctx)
      assert conn.state == :set
    end

    test "sets state on econnrefused", ctx do
      Bypass.down(ctx.bypass)
      conn = call_proxy(ctx)
      assert conn.status == 503
      assert conn.state == :set
    end

    defmodule TimeoutClient do
      use Tesla
      def build() do
        Tesla.build_client([{__MODULE__, []}])
      end

      def call(_env, _next, _opts) do
        raise %Tesla.Error{message: "adapter error: timeout",
                           reason: :timeout}
      end
    end

    test "sets state on request timeout", ctx do
      plug = Proxy.init([origin: ctx.origin, client: TimeoutClient.build])
      conn = call_proxy(%{ctx | plug: plug})
      assert conn.status == 504
      assert %Tesla.Error{reason: :timeout} = conn.assigns.error
      assert conn.state == :set
    end

    test "proxies POST to origin", ctx do
      Bypass.expect(ctx.bypass, fn conn ->
        assert conn.method == "POST"
        Plug.Conn.send_resp(conn, 200, "")
      end)
      call_proxy(ctx, method: :post)
    end

    test "proxies path", ctx do
      Bypass.expect(ctx.bypass, fn conn ->
        assert conn.request_path == "/test"
        Plug.Conn.send_resp(conn, 200, "")
      end)
      call_proxy(ctx, path: "/test")
    end

    test "returns status", ctx do
      Bypass.expect(ctx.bypass, fn conn ->
        Plug.Conn.send_resp(conn, 201, "")
      end)
      conn = call_proxy(ctx)
      assert conn.status == 201
    end
  end

  defp call_proxy(ctx, opts \\ []) do
    host   = Keyword.get(opts, :host, "example.org")
    method = Keyword.get(opts, :method, :get)
    path   = Keyword.get(opts, :path, "/")
    url = ctx.origin <> path
    method
    |> conn(url)
    |> Map.put(:host, host)
    |> Proxy.call(ctx.plug)
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
    [origin: "http://localhost:#{bypass.port}"]
  end

  defp plug(%{origin: origin}) do
    [plug: Proxy.init(origin: origin)]
  end
end
