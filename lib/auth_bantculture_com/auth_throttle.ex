defmodule AuthBantcultureCom.AuthThrottle do
  @moduledoc false

  use GenServer

  @table :auth_bantculture_com_throttle
  @window_seconds 600
  @max_attempts 10
  @cleanup_interval_ms 60_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def allowed?(key, now \\ System.system_time(:second)) do
    case :ets.lookup(@table, key) do
      [] -> :ok
      [{^key, _count, first_at}] when now - first_at >= @window_seconds -> :ok
      [{^key, count, _first_at}] when count < @max_attempts -> :ok
      _ -> {:error, :throttled}
    end
  end

  def record_failure(key, now \\ System.system_time(:second)) do
    case :ets.lookup(@table, key) do
      [] -> :ets.insert(@table, {key, 1, now})
      [{^key, _count, first_at}] when now - first_at >= @window_seconds -> :ets.insert(@table, {key, 1, now})
      [{^key, count, first_at}] -> :ets.insert(@table, {key, count + 1, first_at})
    end

    :ok
  end

  def clear(key), do: :ets.delete(@table, key)

  @impl true
  def init(state) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true, write_concurrency: true])
    schedule_cleanup()
    {:ok, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.system_time(:second)

    :ets.tab2list(@table)
    |> Enum.each(fn {key, _count, first_at} ->
      if now - first_at >= @window_seconds do
        :ets.delete(@table, key)
      end
    end)

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup, do: Process.send_after(self(), :cleanup, @cleanup_interval_ms)
end
