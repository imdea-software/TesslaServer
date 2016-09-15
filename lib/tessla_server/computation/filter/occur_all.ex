defmodule TesslaServer.Node.Filter.OccurAll do
  @moduledoc """
  Implements a `Node` that emits Events whenever both input stream are emitting an Event.

  The `state.operands` list has to hold two integers specifying the ids of the two streams.
  """

  alias TesslaServer.{SimpleNode, Event}
  alias TesslaServer.Node.{History, State}

  use SimpleNode

  def perform_computation(timestamp, event_map, state) do
    [op1, op2] = state.operands
    event1 = event_map[op1]
    event2 = event_map[op2]
    cond do
      !event1 or !event2 ->
        :wait
      event1.timestamp == timestamp && event2.timestamp == timestamp ->
        {:ok, %Event{
          stream_id: state.stream_id, timestamp: timestamp
        }}
      true ->
        :wait
    end
  end
end
