defmodule Ballast.Mixfile do
  use Mix.Project

  def project do
    [app: :ballast,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == [:prod, :heroku],
     start_permanent: Mix.env in [:prod, :heroku],
     deps: deps(Mix.env)]
  end

  def application do
    [extra_applications: [:logger],
     mod: {Ballast, []}]
  end

  defp deps(_env) do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.2"},
      {:poison, "~> 3.0"},
      {:tesla, "~> 0.6.0"},
      {:hackney, "~> 1.6"},
      {:bypass, "~> 0.5.1", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
    ]
  end
end
