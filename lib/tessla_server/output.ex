defmodule TesslaServer.Output do
  @moduledoc """
  Used to log outputs.
  Has to be initialized at startup to hold the ids and names of nodes that should be logged.
  """

  @typep timestamp :: Timex.Types.timestamp

  require Logger

  alias TesslaServer.{Node, Event}

  @spec start(%{Node.id => String.t}) :: {:ok, pid}
  def start(map \\ %{}) do
    Agent.start_link(fn -> map end, name: __MODULE__)
  end

  @spec log_new_progress(Node.id, timestamp) :: nil
  def log_new_progress(id, new_progress) do
    name = Agent.get(__MODULE__, &Map.get(&1, id))
    if name, do: Logger.debug "Stream #{name} progressed to #{inspect new_progress}"
  end

  @spec log_new_outputs(Node.id, [Event.t]) :: nil
  def log_new_outputs(_, []), do: nil
  def log_new_outputs(id, events) do
    name = Agent.get(__MODULE__, &Map.get(&1, id))
    if name, do: Logger.debug ("New outputs of #{name}: \n" <> format(events))
  end

  defp format(events) do
    rows = Enum.map events, fn event ->
      [inspect(event.timestamp), inspect(event.value)]
    end
    header = ~w(time value)
    TableRex.quick_render!(rows, header)
  end

end