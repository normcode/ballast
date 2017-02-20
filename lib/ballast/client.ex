defmodule Ballast.Client do

  use Tesla, only: [:request], docs: false

  adapter :hackney

  def build(opts \\ []) do
    origin = Keyword.fetch!(opts, :origin)
    Tesla.build_client([
      {Tesla.Middleware.BaseUrl, origin},
      {__MODULE__, opts},
    ])
  end

  def call(env, next, opts) do
    env
    |> default_user_agent(opts)
    |> Tesla.run(next)
  end

  def default_user_agent(env = %Tesla.Env{headers: %{}}, _opts), do: %{env | headers: []}
  def default_user_agent(env = %Tesla.Env{}, _opts) do
    headers = if List.keymember?(env.headers, "user-agent", 0) do
      env.headers
    else
      [{"user-agent", "ballast/1.0.0"} | env.headers]
    end
    %{env | headers: headers}
  end

end
