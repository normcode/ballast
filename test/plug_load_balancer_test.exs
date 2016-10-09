defmodule PlugLoadBalancerTest do
  use ExUnit.Case

  test "application is running" do
    applications =
      Application.started_applications
      |> Enum.map(&elem(&1, 0))
    assert :plug_load_balancer in applications
  end
end
