defmodule Tracing do
  @moduledoc """
  OpenTelemetry convenience module for often repeated patterns

  ## Tracing with a span

  ```
  require Tracing

  Tracing.with_span "this_is_my_span" do
    // do_work()
  end
  ```

  Also see `with_span_fn/2-3` for continued tracing within a spawned process.

  ## Using the function decorator

  ```
  use Tracing

  @decorate with_span()
  def do_work do
    // do_more_work()
  end
  ```
  """

  defmacro __using__(_) do
    quote do
      require Tracing
      require OpenTelemetry.Tracer
      use Tracing.Decorator
    end
  end

  @doc """
  Returns hexadecimal string you can use to query in Honeycomb on `trace.trace_id`
  """
  @spec trace_id() :: String.t()
  def trace_id do
    case current_span() do
      :undefined ->
        "span_not_found"

      span_ctx ->
        span_ctx
        |> OpenTelemetry.Span.trace_id()
        |> Integer.to_string(16)
        |> String.pad_leading(32, "0")
        |> String.downcase()
    end
  end

  @doc """
  Returns the current span that can be used to add new events or attributes
  """
  @spec current_span() :: any()
  def current_span, do: OpenTelemetry.Tracer.current_span_ctx()

  @doc """
  Sets the current span to current_span() or what is provided
  """
  def set_current_span(span \\ current_span()) do
    OpenTelemetry.Tracer.set_current_span(span)
  end

  @doc """
  Simple wrapper around `OpenTelemetry.Span.set_attributes/2`
  """
  def set_attributes(attrs) do
    OpenTelemetry.Span.set_attributes(
      current_span(),
      attrs
    )
  end

  @doc """
  Simple wrapper around `OpenTelemetry.Span.add_event/2`
  """
  def add_event(name, attrs) do
    OpenTelemetry.Span.add_event(
      current_span(),
      name,
      attrs
    )
  end

  @doc """
  Helper function for propogating opentelemetry by using a map
  """
  def inject_map(meta \\ %{}) do
    meta
    |> Enum.into([])
    |> inject()
    |> Map.new()
  end

  @doc """
  Helper function for propogating opentelemetry by using a map
  """
  def extract_map(map) do
    map
    |> Enum.into([])
    |> extract()
  end

  @doc """
  Simple wrapper around `OpenTelemetry.Tracer.end_span/0`
  """
  def end_span() do
    OpenTelemetry.Tracer.end_span()
  end

  @doc """
  Helper function for propogating opentelemetry
  """
  def inject(keywords \\ []), do: :otel_propagator_text_map.inject(keywords)

  @doc """
  Helper function for propogating opentelemetry
  """
  def extract(keywords), do: :otel_propagator_text_map.extract(keywords)

  @doc """
  Helper function to start Tracing.Monitor
  """
  def monitor(span \\ nil), do: Tracing.Monitor.monitor(span)

  @doc """
  Use this function when defining an anonymous function that will be used in _another process_.
  This function will ensure that the span in the parent process is the parent span of the span in the spawned process.

  ## Examples

  ```
  spawn(Tracing.with_span_fn("do something", [key: :value], fn -> do_something() end))

  Task.start_link(Tracing.with_span_fn("do something", fn -> do_something() end))

  Task.async_stream(things, Tracing.with_span_fn("do something", fn thing -> do_something(thing) end))

  Task.start_link(Tracing.with_span_fn(&do_something/0))
  ```

  ## Options

  You can pass options which are forwarded to `OpenTelemetry.Tracer.with_span/3`. There is **one**
  special option that will also monitor the spawned process and close the span correctly.

  - `:monitor` - set to `true` to monitor the process
  """
  defmacro with_span_fn(name, opts \\ quote(do: %{}), fun) do
    num_args =
      case fun do
        # fn a, b, c -> nil end
        {:fn, _fn_meta, [{:->, _block_meta, [args, _block]}]} -> Enum.count(args)
        # &carrier.book(&1)
        # not (yet) supported: &carrier.book(&1, ...)
        {:&, _, [{{:., _, _}, _, args}]} -> Enum.count(args)
        # &carrier.book/1
        {:&, _, [{:/, _, [{{:., _, _}, _, []}, num_args]}]} -> num_args
      end

    fun_args = Macro.generate_arguments(num_args, __MODULE__)

    quote do
      require OpenTelemetry.Tracer
      parent_span = OpenTelemetry.Tracer.current_span_ctx()

      if unquote(opts)[:monitor] do
        Tracing.monitor(parent_span)
      end

      fn unquote_splicing(fun_args) ->
        OpenTelemetry.Tracer.set_current_span(parent_span)

        OpenTelemetry.Tracer.with_span unquote(name), unquote(opts) do
          unquote(fun).(unquote_splicing(fun_args))
        end
      end
    end
  end

  @doc """
  Simple wrapper around `OpenTelemetry.Tracer.with_span/3`
  """
  defmacro with_span(name, opts \\ quote(do: %{}), list) do
    quote do
      require OpenTelemetry.Tracer
      OpenTelemetry.Tracer.with_span(unquote(name), unquote(opts), unquote(list))
    end
  end

  def setup(elements) do
    Enum.each(elements, &(:ok = setup_element(&1)))
  end

  def setup_element(:aws), do: Tracing.AWSTelemetry.setup()
  def setup_element(:chromic_pdf), do: Tracing.ChromicPDFTelemetry.setup()
  def setup_element(:liveview), do: Tracing.LiveviewTelemetry.setup()
  def setup_element(:oban), do: Tracing.ObanTelemetry.setup()
  def setup_element(:phoenix), do: OpentelemetryPhoenix.setup()
end
