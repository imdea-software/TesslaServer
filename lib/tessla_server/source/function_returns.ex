defmodule TesslaServer.Source.FunctionReturns do
  @moduledoc """
  Implements a `Source` that emits events without a value whenever a specified Function returns.
  The function has to be specified as a `String.t` in `options` under the key `function`.

  """

  alias TesslaServer.SimpleNode

  use SimpleNode

  alias TesslaServer.Event

  def init(state) do
    channel = "function_returns:" <> state.options[:function]
    :gproc.reg({:p, :l, channel})
    :gproc.reg({:p, :l, :tick})
    super %{state | operands: [nil]}
  end

  def perform_computation(timestamp, _, state) do
    processed_event = %Event{timestamp: timestamp,  stream_id: state.stream_id}
    {:ok, processed_event}
  end
end
