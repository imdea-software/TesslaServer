defmodule TesslaServer.Node.Timing.Delay do
  @moduledoc """
  Implements a `Node` that delays the values of an `EventStream` by the amount specified in
  `options` under the key `delay`.
  """

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use Node

  def init_inputs(%{options: %{operand1: name1, operand2: name2}}) do
    Map.new [{name1, %EventStream{name: name1}}, {name2, %EventStream{name: name2}}]
  end

  def perform_computation(timestamp, event_map, state) do
    event = event_map[state.options.operand1]

    {:ok, %Event{
      stream_name: state.stream_name, timestamp: timestamp, value: event.value
    }}
  end
end
