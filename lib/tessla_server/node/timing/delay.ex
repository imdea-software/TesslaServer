defmodule TesslaServer.Node.Timing.Delay do
  @moduledoc """
  Implements a `Node` that delays the values of an `EventStream` by the amount specified in
  `options` under the key `delay`.
  """

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use Node

  def perform_computation(timestamp, event_map, state) do
    event = event_map[state.options.operand1]

    {:ok, %Event{
      stream_id: state.stream_id, timestamp: timestamp, value: event.value
    }}
  end
end
