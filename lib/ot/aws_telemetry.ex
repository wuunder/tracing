defmodule OT.AWSTelemetry do
  require OpenTelemetry.Tracer

  alias __MODULE__
  alias OpenTelemetry.Span

  @tracer_id AWSTelemetry

  def setup do
    :telemetry.attach(
      {AWSTelemetry, :aws_start},
      [:ex_aws, :request, :start],
      &AWSTelemetry.handle_event/4,
      %{}
    )

    :telemetry.attach(
      {AWSTelemetry, :aws_stop},
      [:ex_aws, :request, :stop],
      &AWSTelemetry.handle_event/4,
      %{}
    )

    :telemetry.attach(
      {AWSTelemetry, :aws_exception},
      [:ex_aws, :request, :exception],
      &AWSTelemetry.handle_event/4,
      %{}
    )

    :ok
  end

  def handle_event([:ex_aws, :request, :start], _, meta, _) do
    OpentelemetryTelemetry.start_telemetry_span(@tracer_id, "aws_request", meta, %{kind: :server})
  end

  def handle_event([:ex_aws, :request, :stop], _, meta, _) do
    _ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)
    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  def handle_event(
        [:ex_aws, :request, :exception],
        _,
        %{kind: kind, reason: reason, stacktrace: stacktrace} = meta,
        _
      ) do
    ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)

    exception = Exception.normalize(kind, reason, stacktrace)

    attrs = []

    Span.record_exception(ctx, exception, stacktrace, attrs)
    Span.set_status(ctx, OpenTelemetry.status(:error, ""))

    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end
end
