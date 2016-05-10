defmodule TesslaServer.Node.Filter.Merge do
  @moduledoc """
  Implements a `Node` that merges two event streams.
  The first specified stream takes presedence over the second, meaning if on both streams
  an event happens at the same time, the value of the first will be used.

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the two streams that are the base of the computation.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node

  def perform_computation(timestamp, event_map, state) do
    [op1, op2] = state.operands
    event1 = event_map[op1]
    event2 = event_map[op2]
    latest_event = [event1, event2]
                |> Enum.filter(&(!is_nil(&1)))
                |> Enum.max_by(&(&1.timestamp))

    {:ok, %Event{
      stream_id: state.stream_id, timestamp: timestamp, value: latest_event.value
    }}
  end
end
