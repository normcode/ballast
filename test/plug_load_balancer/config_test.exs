defmodule PlugLoadBalancer.ConfigTest do
  use ExUnit.Case, async: true

  alias PlugLoadBalancer.Config
  alias PlugLoadBalancer.Config.Rule

  describe "PlugLoadBalancer.Config" do
    test "start_link registers name", context do
      assert {:ok, pid} = Config.start_link(context.test)
      assert ^pid = Process.whereis(context.test)
    end

    test "routes/1 defaults to empty", context do
      assert {:ok, pid} = Config.start_link(context.test)
      assert [] == Config.routes(pid)
    end

    test "with Plug", context do
      rules = [[host: "no.path.example.org", plug: {Test.Plug, []}],
               [path: "/no-host", plug: {Test.Plug, []}],
               [host: "example.org", path: "/test", plug: {Test.Plug, [option: :foo]}]]
      assert {:ok, config} = Config.start_link(context.test, rules: rules)
      assert [a, b, c] = Config.routes(config)
      assert_cowboy_route(a, {~c"no.path.example.org", :_, Test.Plug, []})
      assert_cowboy_route(b, {:_, ~c"/no-host", Test.Plug, []})
      assert_cowboy_route(c, {~c"example.org", ~c"/test", Test.Plug,
                              [option: :foo]})
    end

    test "rules/1", context do
      rules = [[host: "example.org", plug: {Test.Plug, [option: :foo]}]]
      assert {:ok, _pid} = Config.start_link(context.test, rules: rules)
      assert [a] = Config.rules(context.test)
      assert a == Rule.new(host: "example.org", plug: Test.Plug, plug_opts: [option: :foo])
    end

    defmodule InitializingPlug do
      @behaviour Plug
      def init(opts), do: {:opts, opts}
      def call(conn, _opts), do: conn
    end

    test "initial state is computed", context do
        rules = [[host: "example.org", plug: {InitializingPlug, [foo: :bar]}]]
        assert {:ok, config} = Config.start_link(context.test, rules: rules)
        assert [a] = Config.routes(config)
        assert_cowboy_route(a, {~c"example.org", :_,
                                InitializingPlug, {:opts, [foo: :bar]}})
    end

    test "update/2", context do
      {:ok, config} = Config.start_link(context.test, rules: [])
      :ok = Config.update(config, rules: [[host: "example.net", path: "/test", plug: {TestPlug, []}]])
      assert [a] = Config.routes(config)
      assert_cowboy_route(a, {~c"example.net", ~c"/test", TestPlug, []}) 
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
    assert route == {host,
                     [{path,
                       Plug.Adapters.Cowboy.Handler,
                       {plug, plug_opts}}]}
  end

end
