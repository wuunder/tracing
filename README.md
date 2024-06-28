# Tracing

Tracing is a library that contains some standardized telemetry modules with ease of use. It allows control over which modules
should be activated.

## Installation

The package can be installed by adding `tracing` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tracing, "~> 0.1.3"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc).

## Setup

Tracing relies on `Tracing.Monitor` that should be added to the children list in your `Application.start/2`.

Add `Tracing.setup/1` to `Application.start/2` too with the modules you want to enable telemetry for.

Also `Tracing.Telemetry` can be started. The defaults are an empty list of measurements for a period of `10_000` ms. Both can be overridden.

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      Tracing.Monitor,
      Tracing.Telemetry,
      # or
      {Tracing.Telemetry, measurements: [], period: 15_000},
      ...
    ]
    opts = [...]

    Tracing.setup([:phoenix, :liveview, :oban, :aws, :chromic_pdf])

    Supervisor.start_link(children, opts)
  end
end
```

