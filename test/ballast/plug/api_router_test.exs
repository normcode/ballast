defmodule Ballast.Plug.ApiRouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Ballast.Plug.ApiRouter

  describe "Ballast.Plug.ApiRouter.spec/1" do
    @default_config_name Ballast.Config

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

  describe "Ballast.ApiRouter" do
    test "GET /api/routes", ctx do
      {:ok, manager} = GenEvent.start_link
      {:ok, config} = Ballast.Config.start_link(
        ctx.test,
        manager: manager,
        rules: [
          [host: "example.org", plug: {Test.Plug, []}],
          [path: "/test", plug: {Test.Plug, [foo: :bar]}],
          [host: "example.com", path: "/test", plug: {Test.Plug, []}]])
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
end
