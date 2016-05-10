defmodule TesslaServer.Source.FunctionReturns do
  @moduledoc """
  Implements a `Source` that emits events without a value whenever a specified Function returns.
  The function has to be specified as a `String.t` in `options` under the key `function`.

  """

  alias TesslaServer.Node

  use Node

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.State

  def init(state) do
    channel = "function_returns:" <> state.options[:function]
    :gproc.reg({:p, :l, channel})
    super state
  end

  def perform_computation(timestamp, _, state) do
    processed_event = %Event{timestamp: timestamp,  stream_id: state.stream_id}
    {:ok, processed_event}
  end
end
