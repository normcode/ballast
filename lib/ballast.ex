defmodule Ballast do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(GenEvent, event_manager_args()),
      worker(Ballast.Config, config_args()),
      Ballast.Plug.ApiRouter.child_spec(api_args()),
      Ballast.ProxyEndpoint.child_spec(proxy_args())
      # supervisor(Ballast.HealthCheck, []),
    ]

    opts = [strategy: :rest_for_one, name: Ballast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp config_args do
    rules = Application.get_env(:ballast, :routes, [])
    [Ballast.Config, [rules: rules]]
  end

  defp api_args do
    Application.get_env(:ballast, :api, [])
  end

  defp proxy_args do
    [config: Ballast.Config,
     manager: Ballast.ProxyEndpoint.Manager]
  end

  defp event_manager_args do
    [[name: Ballast.ProxyEndpoint.Manager]]
  end
end
