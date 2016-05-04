defmodule TesslaServer.Node.Lifted.Eq do
  @moduledoc """
  Implements a `Node` that compares two integer Streams and returns true 
  if both are the same and false otherwise

  To do so the `state.operands` list has to be initialized with two atoms representing the names
  of the streams that should be the base of the computation.
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
        stream_name: state.stream_name, timestamp: timestamp, value: event1.value == event2.value
      }}
    else
      :wait
    end
  end
end
