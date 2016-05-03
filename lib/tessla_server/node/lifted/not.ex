defmodule TesslaServer.Node.Lifted.Not do
  @moduledoc """
  Implements a `Node` that computes the absolute value of a stream

  To do so the `state.options` object has to be initialized with the key `:operand1`
  which must be an atom representing the name of the event stream that should be the base for the computation.
  """

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use Node

  def init_inputs(%{options: %{operand1: name1}}) do
    Map.new [{name1, %EventStream{name: name1}}]
  end

  def perform_computation(timestamp, event_map, state) do
    event = event_map[state.options.operand1]

    {:ok, %Event{
      stream_name: state.stream_name, timestamp: timestamp, value: !event.value
    }}
  end
end
