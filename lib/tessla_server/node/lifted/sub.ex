defmodule TesslaServer.Node.Lifted.Sub do
  @moduledoc """
  Implements a `Node` that substracts two event streams

  To do so the `state.operands` kust has to be initialized with two atoms representing the ids
  of the two streams that are the base of the computation.
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
        stream_id: state.stream_id, timestamp: timestamp, value: event1.value - event2.value
      }}
    else
      :wait
    end
  end
end
