defmodule PlugLoadBalancer.Config do
  alias PlugLoadBalancer.Config.Rule

  defstruct [rules: []]

  def new(opts \\ []) do
    struct(__MODULE__, opts)
  end

  def routes(config) do
    Enum.map(config.rules, &Rule.to_route/1)
  end
end
