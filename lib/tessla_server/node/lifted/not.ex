defmodule TesslaServer.Node.Lifted.Not do
  @moduledoc """
  Implements a `Node` that computes the boolean not of a boolean stream.

  To do so the `state.operands` list has to be initialized with one atom which is equal to
  the name of the stream that should be the base of the computation
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node

  def perform_computation(timestamp, event_map, state) do
    op1 = hd(state.operands)
    event = event_map[op1]

    {:ok, %Event{
      stream_name: state.stream_name, timestamp: timestamp, value: !event.value
    }}
  end
end
