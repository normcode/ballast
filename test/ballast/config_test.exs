defmodule Ballast.ConfigTest do
  use ExUnit.Case, async: true

  alias Ballast.Config
  alias Ballast.Config.Rule

  describe "Ballast.Config" do
    test "start_link registers name", context do
      assert {:ok, pid} = start_link(context.test)
      assert ^pid = Process.whereis(context.test)
    end

    test "routes/1 defaults to empty", context do
      assert {:ok, pid} = start_link(context.test)
      assert [] == Config.routes(pid)
    end

    test "routes/1 to embedded plug", context do
      rules = [[host: "no.path.example.org", plug: {Test.Plug, []}],
               [path: "/no-host", plug: {Test.Plug, []}],
               [host: "example.org", path: "/test", plug: {Test.Plug, [option: :foo]}]]
      assert {:ok, config} = start_link(context.test, rules: rules)
      assert [a, b, c] = Config.routes(config)
      assert_cowboy_route(a, {~c"no.path.example.org", :_, Test.Plug, []})
      assert_cowboy_route(b, {:_, ~c"/no-host", Test.Plug, []})
      assert_cowboy_route(c, {~c"example.org", ~c"/test", Test.Plug,
                              [option: :foo]})
    end

    defmodule InitializingPlug do
      @behaviour Plug
      def init(opts), do: {:opts, opts}
      def call(conn, _opts), do: conn
    end

    test "routes/1 plug initial state is computed", context do
      rules = [[host: "example.org", plug: {InitializingPlug, [foo: :bar]}]]
      assert {:ok, config} = start_link(context.test, rules: rules)
      assert [a] = Config.routes(config)
      assert_cowboy_route(a, {~c"example.org", :_,
                              InitializingPlug, {:opts, [foo: :bar]}})
    end

    test "rules/1 returns rule state", context do
      rules = [[host: "example.org", plug: {Test.Plug, [option: :foo]}]]
      assert {:ok, _pid} = start_link(context.test, rules: rules)
      assert [a] = Config.rules(context.test)
      assert a == Rule.new(host: "example.org", plug: Test.Plug, plug_opts: [option: :foo])
    end

    test "update/2 changes state", context do
      {:ok, config} = start_link(context.test, rules: [])
      :ok = Config.update(config, rules: [[host: "example.net", path: "/test", plug: {Test.Plug, []}]])
      assert [a] = Config.routes(config)
      assert_cowboy_route(a, {~c"example.net", ~c"/test", Test.Plug, []})
    end

    test "update/2 notifies event handlers", context do
      handler = {TestEventHandler, self()}
      {:ok, config} = start_link(context.test, rules: [], update_handler: handler)
      :ok = Config.update(config, rules: [[host: "example.org", plug: {Test.Plug, []}]])
      rule = Rule.new(host: "example.org", plug: Test.Plug, plug_opts: [])
      assert_receive [^rule]
    end
  end

  describe "Ballast.Config.Rule" do
    test "default values" do
      rule = Rule.new
      assert rule.plug == Ballast.Plug.Default
      assert rule.plug_opts == []
      assert rule.host == :_
      assert rule.path == :_
    end
  end

  defp assert_cowboy_route(route, {host, path, plug, plug_opts}) do
    assert route == {host,
                     [{path,
                       Plug.Adapters.Cowboy.Handler,
                       {Ballast.ProxyEndpoint, {plug, plug_opts}}}]}
  end

  defp start_link(name, opts \\ []) do
    {:ok, manager} = GenEvent.start_link
    handler = {TestEventHandler, self()}

    opts =
      opts
      |> Keyword.put_new(:manager, manager)
      |> Keyword.put_new(:update_handler, handler)
    Config.start_link(name, opts)
  end
end
