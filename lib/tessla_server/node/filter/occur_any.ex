defmodule TesslaServer.Node.Filter.OccurAny do
  @moduledoc """
  Implements a `Node` that emits Events whenever one input stream is emitting an Event.

  The `state.operands` list has to hold two integers specifying the ids of the two streams.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node

  def perform_computation(timestamp, _, state) do
    {:ok, %Event{
      stream_id: state.stream_id, timestamp: timestamp
    }}
  end
end
