defmodule BallastTest do
  use ExUnit.Case

  test "application is running" do
    applications =
      Application.started_applications
      |> Enum.map(&elem(&1, 0))
    assert :ballast in applications
  end
end
