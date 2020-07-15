defmodule Hush.MixProject do
  use Mix.Project

  @version "0.0.1"
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
      preferred_cli_env: [coveralls: :test, "coveralls.github": :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12", only: [:test]},
      {:inch_ex, only: :docs}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url
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
      links: %{"GitHub" => "https://github.com/gordalina/hush"}
    ]
  end
end
