defmodule PlugLoadBalancer.Config do
  use GenServer
  alias PlugLoadBalancer.Config.Rule

  defstruct [table: nil, rules: []]

  def start_link(name, opts \\ []) do
    rules = create_rules(opts)
    GenServer.start_link(__MODULE__, {name, rules}, name: name)
  end

  def routes(config) do
    GenServer.call(config, :routes)
  end

  def update(config, opts) do
    GenServer.call(config, {:update, opts})
  end

  def rules(config) do
    GenServer.call(config, :rules)
  end

  defp new(opts) do
    struct!(__MODULE__, opts)
  end

  def init({table_name, rules}) do
    state = new(table: table_name, rules: rules)
    {:ok, state}
  end

  def handle_call(:routes, _from, state) do
    routes = Enum.map(state.rules, &Rule.to_route/1)
    {:reply, routes, state}
  end

  def handle_call({:update, args}, _from, state=%__MODULE__{}) do
    rules = create_rules(args)
    state = %{state | rules: rules}
    {:reply, :ok, state}
  end

  def handle_call(:rules, _from, state = %__MODULE__{rules: rules}) do
    {:reply, rules, state}
  end

  defp create_rules(args) do
    args
    |> Keyword.get(:rules, [])
    |> Enum.map(&create_rule/1)
  end

  defp create_rule(rule) do
    rule
    |> Enum.map(fn e ->
      case e do
        {:plug, {plug, plug_opts}} -> [{:plug, plug}, {:plug_opts, plug_opts}]
        {key, value} -> {key, value}
      end
    end)
    |> List.flatten()
    |> Rule.new()
  end
end
