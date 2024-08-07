defmodule Tracing.Monitor do
  use GenServer

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    _table_id = :ets.new(__MODULE__, [:bag, :public, {:write_concurrency, true}, :named_table])
    {:ok, nil}
  end

  def handle_call({:monitor, pid}, _from, state) do
    Process.monitor(pid)
    {:reply, :ok, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, :normal}, state) do
    :ets.take(__MODULE__, pid)
    |> Enum.each(fn {_pid, ctx} ->
      _span_ctx = Tracing.set_current_span(ctx)
      _ = Tracing.end_span()
    end)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, {:shutdown, _}}, state) do
    :ets.take(__MODULE__, pid)
    |> Enum.each(fn {_pid, ctx} ->
      _span_ctx = Tracing.set_current_span(ctx)
      _ = Tracing.end_span()
    end)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    :ets.take(__MODULE__, pid)
    |> Enum.each(fn {_pid, ctx} ->
      Tracing.set_current_span(ctx)
      Tracing.add_event("Process died", [{"reason", inspect(reason)}])
      Tracing.end_span()
    end)

    {:noreply, state}
  end

  @doc """
  Start monitoring the given span. If the span is not set, it defaults to `Tracing.current_span()`
  """
  def monitor(span \\ nil) do
    span = span || Tracing.current_span()

    if Application.fetch_env!(:opentelemetry, :processors) != [] do
      # monitor first, because the monitor is necessary to clean the ets table.
      :ok = GenServer.call(__MODULE__, {:monitor, self()})
      true = :ets.insert(__MODULE__, {self(), span})
    end
  end
end
