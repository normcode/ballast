defmodule Ballast do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(GenEvent, event_manager_args()),
      worker(Ballast.Config, config_args()),
      Ballast.Plug.ApiRouter.child_spec(api_args()),
      Ballast.ProxyEndpoint.child_spec(proxy_args()),
      # supervisor(Ballast.HealthCheck, []),
    ]

    opts = [strategy: :rest_for_one, name: Ballast.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp config_args do
    [config_name, [rules: routes(),
                   listener: listener_ref(),
                   update_handler: update_handler()]]
  end

  defp api_args do
    [port: api_port()]
  end

  defp proxy_args do
    [config: config_name(),
     manager: event_manager_name(),
     port: proxy_port()]
  end

  defp event_manager_args do
    [[name: event_manager_name()]]
  end

  defp config_name(), do: Application.get_env(:ballast, :config_name, Ballast.Config)
  defp routes(), do: Application.get_env(:ballast, :routes, [])
  defp listener_ref(), do: Application.get_env(:ballast, :listener_ref, Ballast.ProxyEndpoint.HTTP)
  defp update_handler(), do: {Ballast.ProxyUpdateHandler, [listener: listener_ref()]}
  defp event_manager_name(), do: Ballast.ProxyEndpoint.Manager
  defp proxy_port(), do: Application.get_env(:ballast, :proxy_port, 8080)
  defp api_port(), do: Application.get_env(:ballast, :api_port, 5000)
end
