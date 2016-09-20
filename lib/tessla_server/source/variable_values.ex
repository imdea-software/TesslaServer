defmodule TesslaServer.Source.VariableValues do
  @moduledoc """
  Implements a `Source` that emits a Signal holding the most recent value of a variable.
  The variable has to be specified as a `String.t` in `options` under the key `variable`.
  """

  alias TesslaServer.{GenComputation, Registry}

  use GenComputation

  def init(state) do
    channel = "variable_values:" <> state.options[:variable]
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
