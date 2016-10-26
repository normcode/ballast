defmodule Ballast.Mixfile do
  use Mix.Project

  def project do
    [app: :ballast,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(Mix.env)]
  end

  def application do
    [applications: [:logger,
                    :cowboy,
                    :plug,
                    :httpotion],
     mod: {Ballast, []}]
  end

  defp deps(_env) do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.2"},
      {:poison, "~> 3.0"},
      {:httpotion, "~> 3.0"},
      {:bypass, "~> 0.5.1", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev}
    ]
  end
end
