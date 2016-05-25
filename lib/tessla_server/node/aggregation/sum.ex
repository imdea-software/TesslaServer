defmodule TesslaServer.Node.Aggregation.Sum do
  @moduledoc """
  Implements a `Node` that emits a Signal holding the summed value of all events happened on the
  input EventStream.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which events' values should be summed.
  """

  alias TesslaServer.{SimpleNode, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use SimpleNode
  use Timex

  def perform_computation(timestamp, event_map, state) do
    new_event = event_map[hd(state.operands)]
    last_event = History.latest_output state.history
    {:ok, %Event{
      stream_id: state.stream_id, timestamp: timestamp, value: last_event.value + new_event.value
    }}
  end

  def init_output(state) do
    default_value = 0
    default_event = %Event{stream_id: state.stream_id, value: default_value}

    {:ok, stream} = EventStream.add_event(state.history.output, default_event)
    %{stream | type: output_stream_type}
  end

  def output_stream_type, do: :signal
end
