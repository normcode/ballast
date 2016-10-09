defmodule PlugLoadBalancer.ConfigTest do
  use ExUnit.Case, async: true

  alias PlugLoadBalancer.Config
  alias PlugLoadBalancer.Config.Rule

  defmodule Test.Plug do
    @behaviour Plug
    def init(opts), do: opts
    def call(conn, _opts), do: conn
  end

  describe "PlugLoadBalancer.Config" do
    test "routes/1 defaults to empty" do
      config = Config.new
      assert Config.routes(config) == []
    end

    test "routes/1" do
      rules = [
        Rule.new(host: "nopath.example.org", plug: Test.Plug, plug_opts: []),
        Rule.new(path: "/nohost", plug: Test.Plug, plug_opts: []),
        Rule.new(
          host: "example.com",
          path: "/test",
          plug: Test.Plug,
          plug_opts: [origin: "http://localhost:81"]),
      ]
      config = Config.new(rules: rules)
      routes = Config.routes(config)

      assert_cowboy_route(Enum.at(routes, 0), {"nopath.example.org", '_', Test.Plug, []})
      assert_cowboy_route(Enum.at(routes, 1), {'_', '/nohost', Test.Plug, []})
      assert_cowboy_route(Enum.at(routes, 2), {"example.com", "/test", Test.Plug, [origin: "http://localhost:81"]})
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
    assert route == {to_char_list(host), [{to_char_list(path), Plug.Adapters.Cowboy.Handler, {plug, plug_opts}}]}
  end
end
