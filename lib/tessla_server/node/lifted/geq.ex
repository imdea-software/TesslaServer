defmodule TesslaServer.Node.Lifted.Geq do
  @moduledoc """
  Implements a `Node` that compares two integer Streams and returns true if the first is
  greater or equal to the second and false otherwise.

  To do so the `state.operands` list has to be initialized with two integers representing the ids of
  the streams that should be the base for the computation.
  The first Stream must be greater than the second to yield `true`.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node

  def perform_computation(timestamp, event_map, state) do
    [op1, op2] = state.operands
    event1 = event_map[op1]
    event2 = event_map[op2]

    if event1 && event2 do
      {:ok, %Event{
        stream_id: state.stream_id, timestamp: timestamp, value: event1.value >= event2.value
      }}
    else
      :wait
    end
  end
end
