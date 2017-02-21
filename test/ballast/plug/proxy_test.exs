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
      Bypass.expect(ctx.bypass, fn conn ->
        Plug.Conn.send_resp(conn, 418, "")
      end)
      conn = call_proxy(ctx)
      assert conn.state == :set
    end

    test "sets status on econnrefused", ctx do
      Bypass.down(ctx.bypass)
      conn = call_proxy(ctx)
      assert conn.status == 503
      assert conn.state == :set
    end

    defmodule RaiseErrorClient do
      use Tesla
      def build(error) do
        Tesla.build_client([{__MODULE__, error}])
      end
      def call(_env, _next, opts) do
        raise %Tesla.Error{message: "adapter error: #{inspect(opts)}",
                           reason: opts}
      end
    end

    test "sets status on request timeout", ctx do
      plug = Proxy.init([origin: ctx.origin,
                         client: RaiseErrorClient.build(:timeout)])
      conn = call_proxy(%{ctx | plug: plug})
      assert conn.status == 504
      assert conn.state == :set
    end

    test "sets status on connect timeout", ctx do
      plug = Proxy.init([origin: ctx.origin,
                         client: RaiseErrorClient.build(:connect_timeout)])
      conn = call_proxy(%{ctx | plug: plug})
      assert conn.status == 503
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

    test "returns body", ctx do
      Bypass.expect(ctx.bypass, fn conn ->
        Plug.Conn.send_resp(conn, 200, "test body")
      end)
      conn = call_proxy(ctx)
      assert conn.resp_body == "test body"
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

  defp origin(%{bypass: bypass}) do
    [origin: "http://localhost:#{bypass.port}"]
  end

  defp plug(%{origin: origin}) do
    [plug: Proxy.init(origin: origin)]
  end

end
