defmodule OT.ChromicPDFTelemetry do
  alias OpenTelemetry.Span
  alias __MODULE__

  @tracer_id ChromicPDFTelemetry

  def setup do
    :telemetry.attach(
      {ChromicPDFTelemetry, :chromic_pdf_start},
      [:chromic_pdf, :print_to_pdf, :start],
      &ChromicPDFTelemetry.handle_event/4,
      %{}
    )

    :telemetry.attach(
      {ChromicPDFTelemetry, :chromic_pdf_stop},
      [:chromic_pdf, :print_to_pdf, :stop],
      &ChromicPDFTelemetry.handle_event/4,
      %{}
    )

    :telemetry.attach(
      {ChromicPDFTelemetry, :chromic_pdf_exception},
      [:chromic_pdf, :print_to_pdf, :exception],
      &ChromicPDFTelemetry.handle_event/4,
      %{}
    )

    :ok
  end

  def handle_event([:chromic_pdf, :print_to_pdf, :start], _, meta, _) do
    OpentelemetryTelemetry.start_telemetry_span(
      @tracer_id,
      "chromic_pdf.#{meta[:document] || "document"}",
      meta,
      %{kind: :server}
    )
  end

  def handle_event([:chromic_pdf, :print_to_pdf, :stop], _, meta, _) do
    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  def handle_event(
        [:chromic_pdf, :print_to_pdf, :exception],
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
