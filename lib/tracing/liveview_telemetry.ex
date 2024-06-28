defmodule Tracing.LiveviewTelemetry do
  require OpenTelemetry.Tracer
  alias __MODULE__
  alias OpenTelemetry.Span

  @tracer_id LiveviewTelemetry

  @event_names [
    [:phoenix, :live_view, :mount, :start],
    [:phoenix, :live_view, :mount, :stop],
    [:phoenix, :live_view, :mount, :exception],
    [:phoenix, :live_view, :handle_params, :start],
    [:phoenix, :live_view, :handle_params, :stop],
    [:phoenix, :live_view, :handle_params, :exception],
    [:phoenix, :live_view, :handle_event, :start],
    [:phoenix, :live_view, :handle_event, :stop],
    [:phoenix, :live_view, :handle_event, :exception],
    [:phoenix, :live_component, :handle_event, :start],
    [:phoenix, :live_component, :handle_event, :stop],
    [:phoenix, :live_component, :handle_event, :exception]
  ]
  def setup do
    :telemetry.attach_many(
      LiveviewTelemetry,
      @event_names,
      &LiveviewTelemetry.handle_event/4,
      %{}
    )
  end

  def handle_event([:phoenix, source, function, :start], _measurements, meta, _config)
      when source in [:live_view, :live_component] do
    %{socket: %{view: live_view}} = meta

    OpentelemetryTelemetry.start_telemetry_span(
      @tracer_id,
      "#{inspect(live_view)}.#{function}",
      meta,
      %{kind: :internal}
    )
    |> Span.set_attributes(meta_based_attributes(meta, source, function))
  end

  def handle_event([:phoenix, source, _function, :stop], _measurements, meta, _config)
      when source in [:live_view, :live_component] do
    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  def handle_event(
        [:phoenix, source, _kind, :exception],
        _measurements,
        %{kind: kind, reason: reason, stacktrace: stacktrace} = meta,
        _config
      )
      when source in [:live_view, :live_component] do
    ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, meta)

    exception = Exception.normalize(kind, reason, stacktrace)

    Span.record_exception(ctx, exception, stacktrace, [])
    Span.set_status(ctx, OpenTelemetry.status(:error, Exception.message(exception)))

    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, meta)
  end

  defp meta_based_attributes(meta, source, function) do
    module =
      case {source, meta} do
        {:live_view, _} -> module_to_string(meta.socket.view)
        {:live_component, %{component: component}} -> module_to_string(component)
      end

    attributes = [
      "liveview.module": module,
      "liveview.callback": Atom.to_string(function)
    ]

    Enum.reduce(meta, attributes, fn
      {:uri, uri}, acc ->
        Keyword.put(acc, :"liveview.uri", uri)

      {:component, component}, acc ->
        Keyword.put(acc, :"liveview.module", module_to_string(component))

      {:event, event}, acc ->
        Keyword.put(acc, :"liveview.event", event)

      _, acc ->
        acc
    end)
  end

  defp module_to_string(module) when is_atom(module) do
    case to_string(module) do
      "Elixir." <> name -> name
      erlang_module -> ":#{erlang_module}"
    end
  end
end
