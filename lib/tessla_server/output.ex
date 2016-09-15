defmodule TesslaServer.Output do
  @moduledoc """
  Used to log outputs.
  Has to be initialized at startup to hold the ids and names of streams that should be logged.

  TODO: Make async in V2
  """

  @typep timestamp :: Timex.Duration.t

  require Logger

  alias TesslaServer.{GenComputation, Event}

  @spec start(%{GenComputation.id => String.t}) :: {:ok, pid}
  def start(map \\ %{}) do
    Agent.start_link(fn -> map end, name: __MODULE__)
  end

  @spec log_new_progress(GenComputation.id, timestamp) :: :ok
  def log_new_progress(id, new_progress) do
    Agent.cast __MODULE__, fn state ->
      if name = Map.get state, id do
        Logger.debug "Stream #{name} progressed to #{inspect new_progress}"
      end
      state
    end
  end

  @spec log_new_outputs(GenComputation.id, [Event.t]) :: :ok
  def log_new_outputs(_, []), do: nil
  def log_new_outputs(id, events) do
    Agent.cast __MODULE__, fn state ->
      if name = Map.get(state, id) do
        formatted = format events
        Logger.info("New outputs of #{name}: \n" <> formatted <> "\n-------------\n")
        state
      end
    end
  end

  defp format(events) do
    rows = Enum.map events, fn event ->
      "time: #{inspect event.timestamp}, value: #{inspect event.value}"
    end
    Enum.join rows, "\n"
  end
end
