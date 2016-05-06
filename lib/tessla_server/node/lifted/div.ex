defmodule TesslaServer.Node.Lifted.Div do
  @moduledoc """
  Implements a `Node` that divides two event streams

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the streams which should be the base of the computation.
  The first Stream will be divided by the second.
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
        stream_id: state.stream_id, timestamp: timestamp, value: event1.value / event2.value
      }}
    else
      :wait
    end
  end
end
