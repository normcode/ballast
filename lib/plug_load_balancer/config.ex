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
    rules =
      opts
      |> Keyword.get(:rules, [])
      |> Enum.map(&create_rule/1)
    GenServer.start_link(__MODULE__, {name, rules}, name: name)
  end

  defp create_rule(rule) do
    attrs = Enum.reduce(rule, [], fn (e, acc) ->
      case e do
        {:plug, {plug, plug_opts}} -> Enum.into([{:plug, plug}, {:plug_opts, plug_opts}], acc)
        {key, value} -> [{key, value} | acc]
      end
    end)
    Rule.new(attrs)
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
