defmodule Tracing.ObanTelemetry do
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

    OpentelemetryMonitor.monitor(OpenTelemetry.Tracer.current_span_ctx())
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
    case OpenTelemetry.Tracer.current_span_ctx() do
      :undefined ->
        nil

      _context ->
        ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)

        exception = Exception.normalize(kind, reason, stacktrace)

        Span.record_exception(ctx, exception, stacktrace, [])
        Span.set_status(ctx, OpenTelemetry.status(:error, ""))
        OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
    end
  end
end
