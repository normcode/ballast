defmodule PlugLoadBalancer.ConfigTest do
  use ExUnit.Case, async: true

  alias PlugLoadBalancer.Config
  alias PlugLoadBalancer.Config.Rule

  describe "PlugLoadBalancer.Config" do
    test "start_link registers name", context do
      assert {:ok, pid} = Config.start_link(context.test)
      assert ^pid = Process.whereis(context.test)
    end

    test "start_link takes initial rules", context do
      rule = Rule.new(plug: Test.Plug)
      assert {:ok, _} = Config.start_link(context.test, rules: [rule])
      assert [route] = Config.routes(context.test)
      assert_cowboy_route(route, {:_, :_, Test.Plug, []})
    end

    test "routes/1 defaults to empty", context do
      assert {:ok, pid} = Config.start_link(context.test)
      assert [] == Config.routes(pid)
    end

    test "routes/1", context do
      rules = [
        Rule.new(host: "nopath.example.org", plug: Test.Plug, plug_opts: []),
        Rule.new(path: "/nohost", plug: Test.Plug, plug_opts: []),
        Rule.new(
          host: "example.com",
          path: "/test",
          plug: Test.Plug,
          plug_opts: [origin: "http://localhost:81"]),
      ]
      assert {:ok, config} = Config.start_link(context.test, rules: rules)
      assert [a, b, c] = Config.routes(config)
      assert_cowboy_route(a, {"nopath.example.org", ~c"_", Test.Plug, []})
      assert_cowboy_route(b, {~c"_", ~c"/nohost", Test.Plug, []})
      assert_cowboy_route(c, {"example.com", "/test", Test.Plug,
                              [origin: "http://localhost:81"]})
    end
  end

  describe "PlugLoadBalancer.Config.Rule" do
    test "defaults" do
      rule = Rule.new
      assert rule.plug == PlugLoadBalancer.Plug.Default
      assert rule.plug_opts == []
      assert rule.host == :_
      assert rule.path == :_
    end
  end

  defp assert_cowboy_route(route, {host, path, plug, plug_opts}) do
    assert route == {to_char_list(host),
                     [{to_char_list(path),
                       Plug.Adapters.Cowboy.Handler,
                       {plug, plug_opts}}]}
  end

end
