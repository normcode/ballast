defmodule Ballast.ProxyUpdateHandlerTest do
  use ExUnit.Case
  alias Ballast.ProxyUpdateHandler
  alias Ballast.Config.Rule

  describe "Ballast.ProxyUpdateHandler" do
    test ":rule event updates cowboy dispatch", ctx do
      {:ok, manager} = GenEvent.start_link
      assert :ok = GenEvent.add_mon_handler(manager, ProxyUpdateHandler, [listener: ctx.test])
      {:ok, _http_pid} = :cowboy.start_http(ctx.test, 1, [], [env: [dispatch: []]])
      assert :ok = GenEvent.sync_notify(manager, {:rules, [Rule.new]})
      assert [env: [dispatch: [_]]] = :ranch.get_protocol_options(ctx.test)
      :cowboy.stop_listener(ctx.test)
    end

    test "compilation errors crashes handler", ctx do
      {:ok, manager} = GenEvent.start_link
      assert :ok = GenEvent.add_mon_handler(manager, ProxyUpdateHandler, [listener: ctx.test])
      {:ok, _http_pid} = :cowboy.start_http(ctx.test, 1, [], [env: [dispatch: [:foo]]])
      rule = Rule.new(plug: :foo)
      assert :ok = GenEvent.sync_notify(manager, {:rules, [rule]})
      assert [env: [dispatch: [:foo]]] = :ranch.get_protocol_options(ctx.test)
      assert_receive {:gen_event_EXIT, ProxyUpdateHandler, _}
      :cowboy.stop_listener(ctx.test)
    end
  end
end
