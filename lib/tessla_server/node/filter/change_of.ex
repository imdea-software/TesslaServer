defmodule TesslaServer.Node.Filter.ChangeOf do
  @moduledoc """
  Implements a `Node` that emits Events with the value of a Signal whenever the Signal changes
  it's value.
  To do so the `state.operands` list has to be initialized with one integer specifying the id of
  the Signal of which the changes should be emitted.
  """

  alias TesslaServer.{SimpleNode, Event}
  alias TesslaServer.Node.{History, State}

  use SimpleNode

  def perform_computation(timestamp, event_map, state) do
    [op1] = state.operands
    signal = event_map[op1]
    latest_output = History.latest_output state.history
    if (latest_output && latest_output.value == signal.value) do
      :wait
    else
      {:ok, %Event{timestamp: timestamp, value: signal.value, stream_id: state.stream_id}}
    end
  end
end
