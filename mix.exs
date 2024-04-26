defmodule OT.MixProject do
  use Mix.Project

  def project do
    [
      app: :ot,
      name: "OT",
      version: "1.0.0",
      elixir: "~> 1.16",
      compilers: Mix.compilers(),
      deps: deps(),
      description: description(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/project.plt"},
        format: :dialyxir,
        ignore_warnings: ".dialyzer_ignore.exs",
        paths: ["_build/dev/lib/ot/ebin"]
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
      {:opentelemetry, "~> 1.3.0"},
      {:opentelemetry_semantic_conventions, "~> 0.2.0"},
      {:opentelemetry_api, "~> 1.2"},
      {:opentelemetry_ecto, "~> 1.1"},
      {:opentelemetry_exporter, "~> 1.6"},
      {:opentelemetry_phoenix, "~> 1.2"},
      {:opentelemetry_phoenix_live_view, "~> 0.1",
       github: "wuunder/opentelemetry-erlang-contrib",
       branch: "opentelemetry_phoenix_live_view",
       sparse: "instrumentation/opentelemetry_phoenix_live_view"},
      {:opentelemetry_monitor, "~> 0.1",
       github: "wuunder/opentelemetry-erlang-contrib",
       branch: "opentelemetry_monitor",
       sparse: "instrumentation/opentelemetry_monitor"},
      {:opentelemetry_telemetry, "~> 1.0.0"},
      {:telemetry, "~> 1.0"},
      {:telemetry_metrics, "~> 0.4"},
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
      name: "ot",
      organization: "wuunder",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/wuunder/ot"}
    ]
  end
end
