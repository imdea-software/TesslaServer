defmodule TesslaServer.Source.VariableValues do
  @moduledoc """
  Implements a `Source` that emits a Signal holding the most recent value of a variable.
  The variable has to be specified in `options` under the key `argument`.

  """

  alias TesslaServer.Node

  use Node

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.State

  def init(state) do
    :gproc.reg({:p, :l, hd(state.options[:argument])})
    super state
  end

  def perform_computation(timestamp, event_map, state) do
    event = hd(Map.values(event_map))
    {value, _} =  event.value
                  |> hd
                  |> Integer.parse # TODO somehow process based on needed type

    processed_event = %Event{timestamp: timestamp, value: value, stream_id: state.stream_id}
    {:ok, processed_event}
  end
end
