defmodule Ballast.ProxyTest do
  use ExUnit.Case, async: true

  alias Ballast.ProxyEndpoint
  alias Ballast.Plug.Proxy
  alias Ballast.Config

  describe "Ballast.ProxyEndpoint.child_spec" do
    @default_config_name Ballast.Config

    test "initially empty", ctx do
      rules = [
        [host: "test.example.com", plug: Proxy, plug_opts: [origin: "example.org"]],
        [host: "example.com", plug: Proxy, plug_opts: [origin: "example.org"]],
      ]
      _ = Config.start_link(ctx.test, rules: rules)
      child_spec = ProxyEndpoint.child_spec(config: ctx.test)
      expected = Plug.Adapters.Cowboy.child_spec(
        :http,
        Ballast.Plug.Proxy,
        [],
        [port: 8080,
         dispatch: []]
      )
      assert expected == child_spec
    end
  end
end
