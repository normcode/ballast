defmodule PlugLoadBalancer do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # worker(PlugLoadBalancer.Config, []),
      # PlugLoadBalancer.Api.spec(...),
      # PlugLoadBalancer.Proxy.spec(...),
      # supervisor(PlugLoadBalancer.HealthCheck, []),
    ]

    opts = [strategy: :one_for_one, name: PlugLoadBalancer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
