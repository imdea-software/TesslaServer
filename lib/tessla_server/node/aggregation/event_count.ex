defmodule TesslaServer.Node.Aggregation.EventCount do
  @moduledoc """
  Implements a `Node` that emits a Signal holding the amount of Events happened on an Event
  Stream.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which events should be counted.
  """

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use Node
  use Timex

  def perform_computation(timestamp, event_map, state) do
    last_event = History.latest_output state.history
    {:ok, %Event{
      stream_id: state.stream_id, timestamp: timestamp, value: last_event.value + 1
    }}
  end

  def init_output(state) do
    default_value = 0
    default_event = %Event{stream_id: state.stream_id, value: default_value}

    {:ok, history} = History.update_output(state.history, default_event)
    history.output
  end
end
