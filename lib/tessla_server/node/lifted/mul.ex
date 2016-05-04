defmodule TesslaServer.Node.Lifted.Mul do
  @moduledoc """
  Implements a `Node` that multiplies two event streams

  To do so the `state.options` object has to be initialized with the keys `:operand1` and `:operand2`,
  which must be atoms representing the names of the event streams that should be multiplied.
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
        stream_name: state.stream_name, timestamp: timestamp, value: event1.value * event2.value
      }}
    else
      :wait
    end
  end
end
