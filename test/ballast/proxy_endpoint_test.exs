defmodule Ballast.ProxyTest do
  use ExUnit.Case, async: true

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
        Ballast.ProxyEndpoint,
        [],
        [port: 8080,
         dispatch: []]
      )
      assert expected == child_spec
    end
  end
end
