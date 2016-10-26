defmodule Test.Plug do
  require Plug
  @behaviour Plug
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule TestEventHandler do
  use GenEvent

  def init(pid) do
    {:ok, pid}
  end

  def handle_event({:rules, event}, pid) do
    send pid, event
    {:ok, pid}
  end

  def handle_event(event, _pid) do
    ExUnit.Assertions.flunk("Unexpected event: #{inspect event}")
  end
end

ExUnit.start(capture_log: true)
Application.ensure_all_started(:bypass)
