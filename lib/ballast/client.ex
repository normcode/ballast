defmodule Ballast.Client do
  use Tesla, only: []

  adapter :hackney

  def build(opts \\ []) do
    origin = Keyword.fetch!(opts, :origin)
    Tesla.build_client([
      {Tesla.Middleware.Normalize, nil},
      {Tesla.Middleware.BaseUrl, origin},
    ])
  end

end
