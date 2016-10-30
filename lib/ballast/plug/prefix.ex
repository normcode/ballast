defmodule Ballast.Plug.Prefix do
  @behaviour Plug
  import Plug.Conn

  def init(opts) do
    prefix = Keyword.fetch!(opts, :path)
    {plug, plug_opts} = Keyword.fetch!(opts, :plug)
    {Plug.Router.Utils.split(prefix), plug, plug.init(plug_opts)}
  end

  def call(conn, {path, plug, plug_opts}) do
    if prefix_match(conn, path) do
      conn
      |> strip_prefix(path)
      |> plug.call(plug_opts)
      |> replace_prefix()
    else
      conn
      |> plug.call(plug_opts)
    end
  end

  defp prefix_match(conn, path) do
    Enum.all?(Enum.zip(path, conn.path_info), fn {a, v} -> a == v end)
  end

  defp strip_prefix(conn = %Plug.Conn{path_info: path, script_name: script}, prefix) do
    {base, new_path} = Enum.split(path, length(path) - length(prefix))
    %{conn |
      path_info: new_path,
      request_path: "/" <> Enum.join(new_path, "/"),
      script_name: script ++ base}
    |> put_private(:ballast_path, path)
    |> put_private(:ballast_script, script)
  end

  defp replace_prefix(conn) do
    %{conn |
      path_info: conn.private.ballast_path,
      request_path: "/" <> Enum.join(conn.private.ballast_path, "/"),
      script_name: conn.private.ballast_script}
  end
end
