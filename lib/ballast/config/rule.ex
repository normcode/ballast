defmodule Ballast.Config.Rule do

  @default_host :_
  @default_path :_
  @default_plug Ballast.Plug.Default
  @default_opts []

  defstruct [host: :_, path: :_, plug: @default_plug, plug_opts: @default_opts]

  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  @cowboy_handler Plug.Adapters.Cowboy.Handler

  def to_route(rule = %__MODULE__{}) do
    opts = rule.plug.init(rule.plug_opts)
    endpoint_opts = Ballast.ProxyEndpoint.init(plug: {rule.plug, opts})
    {to_char_route(rule.host),
     [{to_char_route(rule.path), @cowboy_handler, {Ballast.ProxyEndpoint, endpoint_opts}}]}
  end

  defp to_char_route(nil), do: :_
  defp to_char_route(:_), do: :_
  defp to_char_route(s), do: to_char_list(s)
end

defimpl Poison.Encoder, for: Ballast.Config.Rule do
  alias Ballast.Config.Rule

  def encode(rule = %Rule{path: :_}, opts) do
    Poison.Encoder.Map.encode(%{host: rule.host}, opts)
  end

  def encode(rule = %Rule{host: :_}, opts) do
    Poison.Encoder.Map.encode(%{path: rule.path}, opts)
  end

  def encode(rule = %Rule{}, opts) do
    Poison.Encoder.Map.encode(%{host: rule.host, path: rule.path}, opts)
  end
end
