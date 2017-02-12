defmodule Ballast.Plug.Api.FetchRules do
  import Plug.Conn
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, opts) do
    config = opts[:config]
    rules = Ballast.Config.rules(config)
    put_private(conn, :rules, rules)
  end
end
