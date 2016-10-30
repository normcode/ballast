defmodule Ballast.Plug.PrefixTest do
  use ExUnit.Case
  import Plug.Test

  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    conn
    |> Plug.Conn.assign(:path, conn.path_info)
    |> Plug.Conn.assign(:opts, opts)
    |> Plug.Conn.put_status(418)
  end

  describe "Ballast.Plug.Prefix" do
    alias Ballast.Plug.Prefix

    test "strips prefix" do
      plug = Prefix.init(path: "/test", plug: {__MODULE__, []})
      conn =
        conn(:get, "/test/ballast")
        |> Prefix.call(plug)
      assert_prefix_response(conn, ["ballast"], ["test", "ballast"])
    end

    test "ignores partial matches" do
      plug = Prefix.init(path: "/test", plug: {__MODULE__, []})
      conn =
        conn(:get, "/tests/ballast")
        |> Prefix.call(plug)
      assert_prefix_response(conn, ["tests", "ballast"], ["tests", "ballast"])
    end

    test "ignores incomplete" do
      plug = Prefix.init(path: "/test", plug: {__MODULE__, []})
      conn =
        conn(:get, "/")
        |> Prefix.call(plug)
      assert_prefix_response(conn, [], [])
    end
  end

  defp assert_prefix_response(conn, path, path_info) do
    assert conn.status == 418
    assert conn.state == :unset
    assert conn.assigns.path == path
    assert conn.assigns.opts == []
    assert conn.path_info == path_info
  end
end
