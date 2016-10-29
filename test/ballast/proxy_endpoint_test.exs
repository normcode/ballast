defmodule Ballast.ProxyTest do
  use ExUnit.Case, async: true
  import Plug.Test

  alias Ballast.ProxyEndpoint
  alias Ballast.Plug.Proxy
  alias Ballast.Config

  describe "Ballast.ProxyEndpoint.child_spec" do
    test "initially empty", ctx do
      rules = [
        [host: "test.example.com", plug: Proxy, plug_opts: [origin: "example.org"]],
        [host: "example.com", plug: Proxy, plug_opts: [origin: "example.org"]],
      ]
      {:ok, manager} = GenEvent.start_link
      _ = Config.start_link(ctx.test, manager: manager, rules: rules)
      child_spec = ProxyEndpoint.child_spec(config: ctx.test)
      expected = Plug.Adapters.Cowboy.child_spec(
        :http,
        ProxyEndpoint,
        [],
        [port: 8080,
         dispatch: []]
      )
      assert expected == child_spec
    end
  end

  describe "Ballast.ProxyEndpoint" do
    test "inserts via header" do
      plug = ProxyEndpoint.init([plug: {Test.Plug, []}])
      conn = conn(:get, "/") |> ProxyEndpoint.call(plug)
      assert conn.status == 418
      assert Plug.Conn.get_resp_header(conn, "via") == ["1.1 ballast"]
    end

    test "prepends via header" do
      plug = ProxyEndpoint.init(plug: {Test.Plug, []})
      conn =
        conn(:get, "/")
        |> Plug.Conn.put_resp_header("via", "1.0 test")
        |> ProxyEndpoint.call(plug)
      assert conn.status == 418
      assert Plug.Conn.get_resp_header(conn, "via") == ["1.1 ballast, 1.0 test"]
    end
  end
end
