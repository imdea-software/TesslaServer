defmodule TesslaServer.Node.Lifted.Implies do
  @moduledoc """
  Implements a `Node` that performs an `implies` on two boolean streams

  To do so the `state.options` object has to be initialized with the keys `:operand1` and `:operand2`,
  which must be atoms representing the names of the event streams that should be used.
  """

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use Node

  def init_inputs(%{options: %{operand1: name1, operand2: name2}}) do
    Map.new [{name1, %EventStream{name: name1}}, {name2, %EventStream{name: name2}}]
  end

  def perform_computation(timestamp, event_map, state) do
    event1 = event_map[state.options.operand1]
    event2 = event_map[state.options.operand2]

    if event1 && event2 do
      {:ok, %Event{
        stream_name: state.stream_name, timestamp: timestamp, value: !event1.value or event2.value
      }}
    else
      :wait
    end
  end
end
