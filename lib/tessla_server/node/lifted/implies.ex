defmodule TesslaServer.Node.Lifted.Implies do
  @moduledoc """
  Implements a `Node` that performs an `implies` on two boolean streams

  To do so the `state.operands` list has to be initialized with two atoms representing the names
  of the streams that should be the base of the computation.
  The first stream will be used as the left side of the implies formula.
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
        stream_name: state.stream_name, timestamp: timestamp, value: !event1.value or event2.value
      }}
    else
      :wait
    end
  end
end
