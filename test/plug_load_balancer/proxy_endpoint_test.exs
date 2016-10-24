defmodule PlugLoadBalancer.ProxyTest do
  use ExUnit.Case, async: true

  alias PlugLoadBalancer.ProxyEndpoint
  alias PlugLoadBalancer.Plug.Proxy
  alias PlugLoadBalancer.Config

  describe "PlugLoadBalancer.ProxyEndpoint.child_spec" do
    @default_config_name PlugLoadBalancer.Config

    test "initially empty", ctx do
      rules = [
        [host: "test.example.com", plug: Proxy, plug_opts: [origin: "example.org"]],
        [host: "example.com", plug: Proxy, plug_opts: [origin: "example.org"]],
      ]
      _ = Config.start_link(ctx.test, rules: rules)
      child_spec = ProxyEndpoint.child_spec(config: ctx.test)
      expected = Plug.Adapters.Cowboy.child_spec(
        :http,
        PlugLoadBalancer.Plug.Proxy,
        [],
        [port: 8080,
         dispatch: []]
      )
      assert expected == child_spec
    end

  end
end
