defmodule TesslaServer.Node.Aggregation.SignalMaximum do
  @moduledoc """
  Implements a `Node` that emits the maximum value ever occured on an Signal Stream
  or a default value if it's bigger than all values occured to that point.

  To do so the `state.operands` list has to be initialized with one id representing the id of
  the signal that should be aggregated over
  """

  alias TesslaServer.{SimpleNode, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use SimpleNode
  use Timex

  def perform_computation(timestamp, event_map, state) do
    op1 = hd(state.operands)
    new_event = event_map[op1]
    current_event = EventStream.event_at(state.history.output, timestamp)
    cond do
      is_nil(current_event) ->
        {:ok, %Event{
          stream_id: state.stream_id, timestamp: new_event.timestamp, value: new_event.value
        }}
      new_event.value > current_event.value ->
        {:ok, %Event{
          stream_id: state.stream_id, timestamp: new_event.timestamp, value: new_event.value
        }}
      true ->
        :wait
    end
  end

  def output_stream_type, do: :signal
end
