defmodule TesslaServer.Source.FunctionReturns do
  @moduledoc """
  Implements a `Source` that emits events without a value whenever a specified Function returns.
  The function has to be specified as a `String.t` in `options` under the key `function`.

  """

  alias TesslaServer.{GenComputation, Registry}

  use GenComputation

  def init(state) do
    channel = "function_returns:" <> state.options[:function]
    Registry.subscribe_to channel
    super state
  end

  def process_event_map(_, timestamp, state) do
    event = %Event{
      stream_id: state.stream_id, timestamp: timestamp
    }
    {:ok, event, state.cache}
  end
end
