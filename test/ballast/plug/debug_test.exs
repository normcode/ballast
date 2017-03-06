defmodule Ballast.Plug.DebugTest do
  use ExUnit.Case

  import Plug.Test

  alias Ballast.Plug.Debug

  describe "Ballast.Plug.Debug" do
    test "call/2" do
      plug = Debug.init([])
      conn = conn(:get, "/test/url", headers: [{"Foo", "bar"}])
      |> Debug.call(plug)
      assert conn.status == 200
    end

    test "json/1" do
      conn = conn(:get, "/test/url", headers: [{"Foo", "bar"}])
      |> Debug.json()
      json = Poison.decode!(conn)
      assert Map.get(json, "method") == "GET"
      assert Map.get(json, "headers") == [["content-type", "multipart/mixed; charset: utf-8"]]
    end
  end

end
