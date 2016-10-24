defmodule PlugLoadBalancer do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(PlugLoadBalancer.Config, config_args()),
      PlugLoadBalancer.Plug.ApiRouter.child_spec(api_args()),
      PlugLoadBalancer.ProxyEndpoint.child_spec(proxy_args())
      # supervisor(PlugLoadBalancer.HealthCheck, []),
    ]

    opts = [strategy: :rest_for_one, name: PlugLoadBalancer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp config_args do
    rules = Application.get_env(:plug_load_balancer, :routes, [])
    [PlugLoadBalancer.Config, [rules: rules]]
  end

  defp api_args do
    Application.get_env(:plug_load_balancer, :api, [])
  end

  defp proxy_args do
    [config: PlugLoadBalancer.Config]
  end
end
