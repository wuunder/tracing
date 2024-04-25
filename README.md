# OT

**TODO: Add description**

## Installation

The package can be installed by adding `ot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ot, "~> 1.0.0", github: "wuunder/ot", branch: "main"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc).

## Setup

OT relies on `OpentelemetryMonitor` that should be added to the children list in your `Application.start/2`.

Add `OT.setup/1` to `Application.start/2` too with the modules you want to enable telemetry for.

Also `OT.Telemetry` can be started. The defaults are an empty list of measurements for a period of `10_000` ms. Both can be overridden.

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      OpentelemetryMonitor,
      OT.Telemetry,
      # or
      {OT.Telemetry, measurements: [], period: 15_000},
      ...
    ]
    opts = [...]

    OT.setup([:phoenix, :live_view, :oban, :aws, :chromic_pdf])

    Supervisor.start_link(children, opts)
  end
end
```

