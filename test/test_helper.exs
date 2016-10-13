defmodule Test.Plug do
  @behaviour Plug
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

ExUnit.configure(exclude: [skip: true])
ExUnit.start()
