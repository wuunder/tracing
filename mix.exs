defmodule OT.MixProject do
  use Mix.Project

  def project do
    [
      app: :ot,
      version: "1.0.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:decorator, "~> 1.4"},
      {:opentelemetry, "~> 1.3.0"},
      {:opentelemetry_semantic_conventions, "~> 0.2.0"},
      {:opentelemetry_api, "~> 1.2"},
      {:opentelemetry_ecto, "~> 1.1"},
      {:opentelemetry_exporter, "~> 1.6"},
      {:opentelemetry_phoenix, "~> 1.2"},
      {:opentelemetry_phoenix_liveview, "~> 0.1",
       github: "wuunder/opentelemetry-erlang-contrib",
       branch: "opentelemetry_phoenix_liveview",
       sparse: "instrumentation/opentelemetry_phoenix_liveview"},
      {:opentelemetry_monitor, "~> 0.1",
       github: "wuunder/opentelemetry-erlang-contrib",
       branch: "opentelemetry_monitor",
       sparse: "instrumentation/opentelemetry_monitor",
       override: true},
      {:opentelemetry_telemetry, "~> 1.1"},
      {:telemetry, "~> 1.0", override: true},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end
end
