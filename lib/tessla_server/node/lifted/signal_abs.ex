defmodule TesslaServer.Node.Lifted.SignalAbs do
  @moduledoc """
  Implements a `Node` that computes the absolute value of a stream

  To do so the `state.operands` list has to be initialized with one integer which is equal to
  the `id` of the stream that should be the base of the computation
  """

  alias TesslaServer.{SimpleNode, Event}
  alias TesslaServer.Node.{History, State}

  use SimpleNode

  def perform_computation(timestamp, event_map, state) do
    op1 = hd(state.operands)
    event = event_map[op1]
    new_event = %Event{stream_id: state.stream_id, timestamp: timestamp, value: abs event.value}
    {:ok, new_event}
  end

  def output_stream_type, do: :signal
end
