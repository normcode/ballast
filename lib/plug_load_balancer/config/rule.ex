defmodule PlugLoadBalancer.Config.Rule do

  defstruct [:host, :path, :plug, :plug_opts]

  @cowboy_handler Plug.Adapters.Cowboy.Handler
  @default_host :_
  @default_path :_
  @default_plug PlugLoadBalancer.Plug.Default
  @default_opts []

  def new(opts \\ []) do
    host      = Keyword.get(opts, :host, @default_host)
    path      = Keyword.get(opts, :path, @default_path)
    plug      = Keyword.get(opts, :plug, @default_plug)
    plug_opts = Keyword.get(opts, :plug_opts, @default_opts)
    %__MODULE__{host: host, path: path, plug: plug, plug_opts: plug_opts}
  end

  def to_route(rule = %__MODULE__{}) do
    opts = rule.plug.init(rule.plug_opts)
    {to_char_route(rule.host), [ {to_char_route(rule.path), @cowboy_handler, {rule.plug, opts}} ]}
  end

  defp to_char_route(nil), do: :_
  defp to_char_route(:_), do: :_
  defp to_char_route(s), do: to_char_list(s)
end
