defmodule Tracing.MixProject do
  use Mix.Project

  def project do
    [
      app: :tracing,
      name: "Tracing",
      version: "0.1.4",
      elixir: "~> 1.16",
      compilers: Mix.compilers(),
      deps: deps(),
      description: description(),
      organization: "wuunder",
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/project.plt"},
        format: :dialyxir,
        ignore_warnings: ".dialyzer_ignore.exs",
        paths: ["_build/dev/lib/tracing/ebin"]
      ],
      package: package(),
      start_permanent: Mix.env() == :prod
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:decorator, "~> 1.4"},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:opentelemetry, "~> 1.3.0"},
      {:opentelemetry_semantic_conventions, "~> 0.2.0"},
      {:opentelemetry_api, "~> 1.2"},
      {:opentelemetry_ecto, "~> 1.1"},
      {:opentelemetry_exporter, "~> 1.6"},
      {:opentelemetry_phoenix, "~> 1.2"},
      {:opentelemetry_telemetry, "~> 1.0.0"},
      {:telemetry, "~> 1.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  defp description() do
    """
      Standardized library for using OpenTelemetry / :telemetry in Elixir applications.
      Provides telemetry modules for Phoenix, LiveView, ChromicPDF and Oban. Also contains a Monitor and Telemetry module."
    """
  end

  defp package() do
    [
      name: "tracing",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/wuunder/tracing"}
    ]
  end
end
