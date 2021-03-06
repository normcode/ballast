defmodule Ballast.Config do
  use GenServer
  alias Ballast.Config.Rule

  defstruct [table: nil,
             rules: [],
             listener: Ballast.Plug.Proxy.HTTP,
             manager: Ballast.ProxyEndpoint.Manager,
             update_handler: {Ballast.ProxyUpdateHandler,
                              [listener: Ballast.Plug.Proxy.HTTP]}]

  def start_link(name, opts \\ []) do
    rules = create_rules(opts)
    opts =
      opts
      |> Keyword.put(:rules, rules)
      |> Keyword.put(:table, name)
    GenServer.start_link(__MODULE__, opts, name: name)
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

  def init(opts) do
    state = struct!(__MODULE__, opts)
    {handler, args} = state.update_handler
    :ok = GenEvent.add_mon_handler(state.manager, handler, args)
    _ = Process.send_after(self(), :sync_routes, 100)
    {:ok, state}
  end

  def handle_call(:routes, _from, state) do
    routes = create_routes(state.rules)
    {:reply, routes, state}
  end

  def handle_call({:update, args}, _from, state=%__MODULE__{}) do
    rules = create_rules(args)
    state = %{state | rules: rules}
    GenEvent.notify(state.manager, {:rules, rules})
    {:reply, :ok, state}
  end

  def handle_call(:rules, _from, state = %__MODULE__{rules: rules}) do
    {:reply, rules, state}
  end

  def handle_info(:sync_routes, state) do
    GenEvent.sync_notify(state.manager, {:rules, state.rules})
    {:noreply, state}
  end

  def handle_info({:gen_event_EXIT, _, reason}, state)
  when reason in [:normal, :shutdown] do
    {:ok, state}
  end

  def handle_info({:gen_event_EXIT, _handler, {:swapped, _, _}}, state) do
    {:ok, state}
  end

  def handle_info({:gen_event_EXIT, handler, reason}, %{handler: {handler, _}}) do
    {:stop, {:update_handler_EXIT, reason}}
  end

  def handle_info(message, _state) do
    {:stop, message}
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

  defp create_routes(rules) do
    Enum.map(rules, &Rule.to_route/1)
  end
end
