defmodule TesslaServer.Node.Aggregation.SignalMinimum do
  @moduledoc """
  Implements a `Node` that emits the minimum value ever occured on an Signal Stream
  or a default value if it's smaller than all values occured to that point.

  To do so the `state.operands` list has to be initialized with one integer representing the id of
  the stream that should be aggregated over and the `options` map has to have a key `default`
  which should hold the default value.
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
      new_event.value < current_event.value ->
        {:ok, %Event{
          stream_id: state.stream_id, timestamp: new_event.timestamp, value: new_event.value
        }}
      true ->
        :wait
    end
  end

  def output_stream_type, do: :signal
end
