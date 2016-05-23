defmodule TesslaServer.EventQueue do
  @moduledoc """
  Implements a central EventQueue to process all external Events in a strictly ordered way.
  """

  use Timex
  alias TesslaServer.{Source, EventStream}
  alias __MODULE__

  @type t :: %__MODULE__{channels: %{String.t => EventStream.t}}
  defstruct channels: %{}

  def start do
    Agent.start_link(fn -> %EventQueue{} end, name: __MODULE__)
  end

  def process_external(channel, event) do
    add_event channel, event
    Source.distribute channel, event
  end

  defp add_event(channel, event) do

    stream = Agent.get(__MODULE__, fn queue ->
      Map.get(queue.channels, channel, %EventStream{})
    end)

    updated_stream = case EventStream.add_event stream, event do
      {:ok, updated_stream} -> updated_stream
      {:error, _} -> raise "External Event received out of order #{inspect event}"
    end

    Agent.update(__MODULE__, fn queue ->
      updated_channels = Map.put(queue.channels, channel, updated_stream)
      %{queue | channels: updated_channels}
    end)
  end
end
