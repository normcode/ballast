defmodule BallastTest do
  use ExUnit.Case

  test "application is running" do
    applications =
      Application.started_applications
      |> Enum.map(&elem(&1, 0))
    assert :ballast in applications
  end

  describe "Ballast.port/1" do

    test "loads from environment" do
      System.put_env("TEST_PORT", "5001")
      assert 5001 == Ballast.port({:system, "TEST_PORT"})
    end

    test "converts port string to integer" do
      assert 5000 == Ballast.port(5000)
      assert 5000 == Ballast.port("5000")
      assert :badarg == catch_throw Ballast.port(nil)
    end
  end
end
