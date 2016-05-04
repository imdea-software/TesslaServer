defmodule TesslaServer.Node.Lifted.Min do
  @moduledoc """
  Implements a `Node` that compares two integer Streams and returns the smaller one

  To do so the `state.operands` list has to be initialized with two atoms representing the names
  of the streams that should be compared
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node

  def perform_computation(timestamp, event_map, state) do
    [op1, op2] = state.operands
    event1 = event_map[op1]
    event2 = event_map[op2]

    if event1 && event2 do
      value = if event1.value <= event2.value, do: event1.value, else: event2.value
      {:ok, %Event{
        stream_name: state.stream_name, timestamp: timestamp, value: value
      }}
    else
      :wait
    end
  end
end
