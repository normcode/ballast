defmodule PlugLoadBalancer.Config.Rule do

  defstruct [host: :_, path: :_, plug: PlugLoadBalancer.Plug.Default, plug_opts: []]

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  @cowboy_handler Plug.Adapters.Cowboy.Handler
  def to_route(rule = %__MODULE__{}) do
    opts = rule.plug.init(rule.plug_opts)
    {to_char_list(rule.host), [ {to_char_list(rule.path), @cowboy_handler, {rule.plug, opts}} ]}
  end
end
