defmodule PlugLoadBalancer.Config do
  use GenServer
  alias PlugLoadBalancer.Config.Rule

  defstruct [table: nil, rules: []]

  defp new(opts) do
    struct(__MODULE__, opts)
  end

  def routes(config) do
    GenServer.call(config, :routes)
  end

  def start_link(name, opts \\ []) when is_atom(name) do
    rules = Keyword.get(opts, :rules, [])
    GenServer.start_link(__MODULE__, {name, rules}, name: name)
  end

  def init({table_name, rules}) do
    state = new(table: table_name, rules: rules)
    {:ok, state}
  end

  def handle_call(:routes, _from, state) do
    routes = Enum.map(state.rules, &Rule.to_route/1)
    {:reply, routes, state}
  end
end
