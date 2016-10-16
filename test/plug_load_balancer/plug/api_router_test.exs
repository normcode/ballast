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
    setup [:create_config]

    test "GET /api/routes", %{config: config} do
      plug = ApiRouter.init(config: config)
      conn =
        conn(:get, "/api/routes")
        |> ApiRouter.call(plug)
      assert conn.status == 200
      assert conn.resp_body == "[]"
    end
  end

  def create_config(ctx) do
    {:ok, pid} = PlugLoadBalancer.Config.start_link(ctx.test)
    [config: ctx.test, Config_pid: pid]
  end
end
