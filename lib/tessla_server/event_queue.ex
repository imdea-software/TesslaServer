defmodule TesslaServer.EventQueue do
  @moduledoc """
  Implements the central Event Queue to process all asynchronous Events in a strictly ordered way
  """

  use Timex
  alias TesslaServer.Event
  alias __MODULE__

  defstruct events: [], last_processed_time: Time.zero

  def start do
    Agent.start_link(fn -> %EventQueue{} end, name: __MODULE__)
  end

  def add_internal(event) do
    Agent.update(__MODULE__, fn event_queue -> %{event_queue | events: [event | event_queue.events]} end)
  end

  def process_external(event) do
    Agent.update(__MODULE__, &process_event_queue_upto(&1, event))
  end

  defp process_event_queue_upto(queue, external_event) do
    {todo, later} = queue.events |> Enum.sort_by(&(&1.timestamp)) |> Enum.split_while(&(&1.timestamp < external_event.timestamp))
    IO.puts "later: #{inspect later}"
    IO.puts "now: #{inspect todo}"
    %EventQueue{last_processed_time: external_event.timestamp, events: later}

  end

  defp insert_into_queue(queue, event) do
    cond do
      queue.last_processed_time > event.timestamp ->
        raise "Event #{inspect event} arrived after external event with bigger timestamp and cannot be processed"
      Enum.empty? queue.events ->
        %{queue | events: [event]}
      true ->
        %{queue | events: insert_into_event_list(queue.events, event)}
    end
  end
end
