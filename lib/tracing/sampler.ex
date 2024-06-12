defmodule Tracing.Sampler do
  @behaviour :otel_sampler

  @one_in_hundred ["oban_producers", "oban_jobs"]

  @impl :otel_sampler
  def setup(_sampler_opts) do
    []
  end

  @impl :otel_sampler
  def description(_sampler_config) do
    "Sampler"
  end

  # sample rate here is "1/x events get sent", so if you put 10, then one in ten events get sampled, nine out of ten get discarded.
  defp sample_rate(
         _ctx,
         _trace_id,
         _links,
         _span_name,
         _span_kind,
         %{source: source},
         _sampler_config
       )
       when source in @one_in_hundred do
    100
  end

  defp sample_rate(
         _ctx,
         _trace_id,
         _links,
         _span_name,
         _span_kind,
         _span_attributes,
         _sampler_config
       ) do
    # 1 = always sample
    1
  end

  @impl :otel_sampler
  def should_sample(
        ctx,
        trace_id,
        links,
        span_name,
        span_kind,
        attributes,
        sampler_config
      ) do
    sample_rate =
      sample_rate(
        ctx,
        trace_id,
        links,
        span_name,
        span_kind,
        attributes,
        sampler_config
      )

    {result, _attrs, tracestate} =
      :otel_sampler_trace_id_ratio_based.should_sample(
        ctx,
        trace_id,
        links,
        span_name,
        span_kind,
        attributes,
        :otel_sampler_trace_id_ratio_based.setup(1.0 / sample_rate)
      )

    # Honeycomb wants to know the SampleRate so that it can account for the non-sampled spans
    {result, [SampleRate: sample_rate], tracestate}
  end
end
