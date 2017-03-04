defmodule BallastTest do
  use ExUnit.Case

  test "application is running" do
    applications =
      Application.started_applications
      |> Enum.map(&elem(&1, 0))
    assert :ballast in applications
  end

  test "converts port string to integer" do
    assert 5000 == Ballast.port(5000)
    assert 5000 == Ballast.port("5000")
    assert :badarg == catch_throw Ballast.port(nil)
  end
end
