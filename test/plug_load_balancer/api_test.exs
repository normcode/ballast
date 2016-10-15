defmodule PlugLoadBalancer.ApiTest do
  use ExUnit.Case, async: true
  use Plug.Test

  describe "PlugLoadBalancer.Api.spec/1" do
    alias PlugLoadBalancer.Api
    @default_config_name PlugLoadBalancer.Config

    test "defaults" do
      child_spec = Api.child_spec()
      expected = Plug.Adapters.Cowboy.child_spec(
        :http,
        PlugLoadBalancer.Api,
        [],
        [port: 5000,
         dispatch: [{:_, [], [{:_, [], Plug.Adapters.Cowboy.Handler, {PlugLoadBalancer.Api, [config: @default_config_name]}}]}]])
      assert expected == child_spec
    end
  end

  describe "PlugLoadBalancer.Api" do
    setup [:create_config]

    test "GET /api/routes", %{config: config} do
      alias PlugLoadBalancer.Api
      plug = Api.init(config: config)
      conn =
        conn(:get, "/api/routes")
        |> Api.call(plug)
      assert conn.status == 200
      assert conn.resp_body == "[]"
    end
  end

  def create_config(ctx) do
    {:ok, pid} = PlugLoadBalancer.Config.start_link(ctx.test)
    [config: ctx.test, Config_pid: pid]
  end
end
