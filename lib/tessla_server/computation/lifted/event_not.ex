defmodule TesslaServer.Node.Lifted.EventNot do
  @moduledoc """
  Implements a `Node` that computes the boolean not of a boolean stream.

  To do so the `state.operands` list has to be initialized with one integer which is equal to
  the id of the stream that should be the base of the computation
  """

  alias TesslaServer.{SimpleNode, Event}
  alias TesslaServer.Node.{History, State}

  use SimpleNode

  def perform_computation(timestamp, event_map, state) do
    op1 = hd(state.operands)
    event = event_map[op1]

    {:ok, %Event{
      stream_id: state.stream_id, timestamp: timestamp, value: !event.value
    }}
  end
end
