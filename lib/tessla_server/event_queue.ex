defmodule TesslaServer.EventQueue do
  @moduledoc """
  Implements the central Event Queue to process all asynchronous Events in a strictly ordered way
  """

  use Timex
  alias TesslaServer.Source
  alias __MODULE__

  defstruct events: [], last_processed_time: Time.zero

  def start do
    Agent.start_link(fn -> %EventQueue{} end, name: __MODULE__)
  end

  def process_external(event) do
    add_event event
    Source.distribute event
  end

  defp add_event(event) do
    last_processed_time = Agent.get(__MODULE__, &(&1.last_processed_time))
    if (last_processed_time > event.timestamp) do
      raise "External Event received with smaller timestamp than a previous."
    end

    Agent.update(__MODULE__, fn event_queue ->
      %{event_queue |
       events: [event | event_queue.events],
       last_processed_time: event.timestamp}
    end)
  end
end
