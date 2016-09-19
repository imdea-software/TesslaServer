defmodule TesslaServer.Source.FunctionCalls do
  @moduledoc """
  Implements a `Source` that emits events without a value whenever a specified Function is
  called.
  The function has to be specified as a `String.t` in `options` under the key `function`.

  """

  alias TesslaServer.GenComputation

  use GenComputation

  def init(state) do
    channel = "function_calls:" <> state.options[:function]
    :gproc.reg({:p, :l, channel})
    super state
  end

  # def perform_computation(timestamp, _, state) do
  #   processed_event = %Event{timestamp: timestamp,  stream_id: state.stream_id}
  #   {:ok, processed_event}
  # end
end
