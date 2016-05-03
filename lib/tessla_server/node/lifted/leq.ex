defmodule TesslaServer.Node.Lifted.Leq do
  @moduledoc """
  Implements a `Node` that compares two integer Streams and returns true if the first is
  smaller or equal to the second and false otherwise.

  To do so the `state.options` object has to be initialized with the keys `:operand1` and `:operand2`,
  which must be atoms representing the names of the event streams that should be compared.
  """

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use Node

  def perform_computation(timestamp, event_map, state) do
    [op1, op2] = state.operands
    event1 = event_map[op1]
    event2 = event_map[op2]

    if event1 && event2 do
      {:ok, %Event{
        stream_name: state.stream_name, timestamp: timestamp, value: event1.value <= event2.value
      }}
    else
      :wait
    end
  end
end
