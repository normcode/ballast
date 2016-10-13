defmodule PlugLoadBalancer.Config do
  use GenServer
  alias PlugLoadBalancer.Config.Rule

  defstruct [table: nil, rules: []]

  defp new(opts) do
    struct!(__MODULE__, opts)
  end

  def routes(config) do
    GenServer.call(config, :routes)
  end

  def start_link(name, opts \\ []) when is_atom(name) do
    user_rules = Keyword.get(opts, :rules, [])
    rules = create_rules(user_rules)
    GenServer.start_link(__MODULE__, {name, rules}, name: name)
  end

  defp create_rules(rules) do
    Enum.map(rules, fn rule ->
      {plug, plug_opts} = rule[:plug]
      Rule.new(host: rule[:host], path: rule[:path], plug: plug, plug_opts: plug_opts)
    end)
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
