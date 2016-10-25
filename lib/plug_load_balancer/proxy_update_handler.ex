defmodule PlugLoadBalancer.ProxyUpdateHandler do
  use GenEvent

  def init(opts) do
    cowboy_listener = Keyword.fetch!(opts, :listener)
    {:ok, cowboy_listener}
  end

  def handle_event({:rules, rules}, listener) do
    alias PlugLoadBalancer.Config.Rule
    routes = Enum.map(rules, &Rule.to_route/1)
    dispatch = :cowboy_router.compile(routes)
    :ok = :cowboy.set_env(listener, :dispatch, dispatch)
    {:ok, listener}
  end
end
