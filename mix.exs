defmodule MsLuis.Mixfile do
  use Mix.Project

  def project do
    [app: :ms_luis,
     version: "2.0.0",
     elixir: "~> 1.4",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ivar, "~> 0.7.0"},
      {:ivar_httpoison, "~> 0.1.0"},
      {:poison, "~> 3.0"},

      # we currently need this as running on windows fails with idna version 5
      {:idna, "~> 4.0"},

      # dev deps
      {:ex_doc, "~> 0.15.0", only: :dev},
      {:credo, "~> 0.7.2", only: [:dev, :test]},
      {:bypass, "~> 0.6.0", only: :test}
    ]
  end

  defp description do
    "A small library that can send requests to the Microsoft LUIS service."
  end

  defp package do
    [name: :ms_luis,
     maintainers: ["swelham"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/swelham/ms_luis"}]
  end
end
