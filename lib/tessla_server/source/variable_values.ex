defmodule TesslaServer.Source.VariableValues do
  @moduledoc """
  Implements a `Source` that emits a Signal holding the most recent value of a variable.
  The variable has to be specified as a `String.t` in `options` under the key `variable`.
  """

  alias TesslaServer.GenComputation

  use GenComputation

  def init(state) do
    channel = "variable_values:" <> state.options[:variable]
    :gproc.reg({:p, :l, channel})
    super state
  end

  # def perform_computation(timestamp, event_map, state) do
  #   event = hd(Map.values(event_map))
  #   {value, _} =  event.value
  #                 |> Integer.parse # somehow process based on needed type

  #   processed_event = %Event{timestamp: timestamp, value: value, stream_id: state.stream_id}
  #   {:ok, processed_event}
  # end
end
