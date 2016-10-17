defmodule PlugLoadBalancer.Plug.ApiRouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias PlugLoadBalancer.Plug.ApiRouter

  describe "PlugLoadBalancer.Plug.ApiRouter.spec/1" do
    @default_config_name PlugLoadBalancer.Config

    test "defaults" do
      child_spec = ApiRouter.child_spec()
      expected = Plug.Adapters.Cowboy.child_spec(
        :http,
        ApiRouter,
        [],
        [port: 5000,
         dispatch: [
           {:_, [], [{:_, [], Plug.Adapters.Cowboy.Handler, {ApiRouter, [config: @default_config_name]}}]}]]
      )
      assert expected == child_spec
    end
  end

  describe "PlugLoadBalancer.ApiRouter" do
    test "GET /api/routes", ctx do
      {:ok, config} = PlugLoadBalancer.Config.start_link(ctx.test, rules: [
            [host: "example.org", plug: {TestPlug, []}],
            [path: "/test", plug: {TestPlug, [foo: :bar]}],
            [host: "example.com", path: "/test", plug: {TestPlug, []}]
          ])
      plug = ApiRouter.init(config: config)
      conn =
        conn(:get, "/api/routes")
        |> ApiRouter.call(plug)
      assert conn.status == 200
      resp = Poison.decode!(conn.resp_body)
      assert resp == [
        %{"host" => "example.org"},
        %{"path" => "/test"},
        %{"host" => "example.com", "path" => "/test"}
      ]
    end
  end

  def create_config(ctx) do
    {:ok, pid} = PlugLoadBalancer.Config.start_link(ctx.test)
    [config: ctx.test, Config_pid: pid]
  end
end
