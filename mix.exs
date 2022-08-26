defmodule Hush.MixProject do
  use Mix.Project

  @version "1.0.1"
  @source_url "https://github.com/gordalina/hush"

  def project do
    [
      app: :hush,
      version: @version,
      elixir: "~> 1.10",
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: @source_url,
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:mox, "~> 1.0", only: :test},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_check, "~> 0.13", only: :dev, runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test, runtime: false},
      {:sobelow, "~> 0.11", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support"] ++ elixirc_paths(nil)
  defp elixirc_paths(_), do: ["lib"]

  defp description() do
    "Extensible runtime configuration loader with pluggable providers"
  end

  defp package() do
    [
      name: "hush",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
