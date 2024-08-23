defmodule Tracing.ObanTelemetry do
  @moduledoc """
  Handles telemetry and events for Oban workers.

  Allows a function `reportable?/1` to be set in an oban worker to define in which case exceptions should be reported or
  not. If `reportable?/1` does not exist, all errors will be reported.

  ## Example

  ```elixir
  defmodule MyApp.Application do
    use Application

    def start(_type, _args) do
      # ...
      Tracing.setup([:oban])
      Supervisor.start_link([], [name: MyApp.Supervisor])
    end
  end

  defmodule MyApp.ObanWorker do
    use Oban.Worker, queue: "webhooks"

    @impl Oban.Worker
    def perform(args) do
      # execute
    end

    def reportable?(meta) do
      meta.attempt >= 3
    end
  end
  ```
  """
  require OpenTelemetry.Tracer

  alias __MODULE__
  alias OpenTelemetry.Span

  @tracer_id ObanTelemetry

  def setup do
    :telemetry.attach(
      {ObanTelemetry, :job_start},
      [:oban, :job, :start],
      &ObanTelemetry.handle_event/4,
      %{}
    )

    :telemetry.attach(
      {ObanTelemetry, :job_stop},
      [:oban, :job, :stop],
      &ObanTelemetry.handle_event/4,
      %{}
    )

    :telemetry.attach(
      {ObanTelemetry, :job_exception},
      [:oban, :job, :exception],
      &ObanTelemetry.handle_event/4,
      %{}
    )

    :ok
  end

  def handle_event(
        [:oban, :job, :start],
        _,
        %{
          job: %{
            worker: worker,
            queue: queue,
            meta: job_meta,
            id: id,
            scheduled_at: scheduled_at,
            attempted_at: attempted_at,
            priority: priority
          }
        } = meta,
        _
      ) do
    Tracing.extract_map(job_meta)

    # microsecond precision
    queue_time_us = DateTime.diff(attempted_at, scheduled_at, :microsecond)
    # display as milliseconds
    queue_time_ms = queue_time_us / 1_000

    attributes = [
      "oban.worker": worker,
      "oban.queue": queue,
      "oban.job_id": id,
      "oban.scheduled_at": DateTime.to_iso8601(scheduled_at),
      "oban.attempted_at": DateTime.to_iso8601(attempted_at),
      "oban.queue_time_ms": queue_time_ms,
      "oban.priority": priority
    ]

    OpentelemetryTelemetry.start_telemetry_span(@tracer_id, "oban.#{worker}", meta, %{
      kind: :server
    })
    |> Span.set_attributes(attributes)

    Tracing.monitor()
  end

  def handle_event([:oban, :job, :stop], _, meta, _) do
    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  def handle_event(
        [:oban, :job, :exception],
        _,
        %{kind: kind, reason: reason, stacktrace: stacktrace} = meta,
        _
      ) do
    Tracing.set_attributes(meta: inspect(meta))

    with {:span, context} when context != :undefined <- {:span, Tracing.current_span()},
         {:reportable, true} <- {:reportable, reportable?(meta)} do
      ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)

      exception = Exception.normalize(kind, reason, stacktrace)

      Span.record_exception(ctx, exception, stacktrace, [])
      Span.set_status(ctx, OpenTelemetry.status(:error, ""))
      OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
    else
      {:reportable, false} ->
        nil

      {:reportable, {:error, _}} ->
        ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)
        Span.set_status(ctx, OpenTelemetry.status(:error, ""))
        OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)

      {:span, :undefined} ->
        nil
    end
  end

  # Allows configurable reporting. By default it will always report, but it allows the oban worker module to specify if
  # it needs a custom configurable report true|false option.
  defp reportable?(%{job: %{worker: worker_name}} = meta) when is_binary(worker_name) do
    module =
      worker_name
      |> String.split(".")
      |> Module.safe_concat()

    if Code.ensure_loaded?(module) && function_exported?(module, :reportable?, 1) do
      module.reportable?(meta)
    else
      true
    end
  rescue
    ArgumentError ->
      {:error, RuntimeError.exception("unknown worker: #{worker_name}")}
  end
end
