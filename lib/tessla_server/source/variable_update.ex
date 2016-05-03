defmodule TesslaServer.Source.VariableUpdate do
  @moduledoc """
  Implements a `Source` that emits the most recent value for a variable

  """

  alias TesslaServer.Node

  use Node

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.State

  def init(state) do
    :gproc.reg({:p, :l, hd(state.operands)})
    super state
  end

  def perform_computation(timestamp, event_map, state) do
    event = event_map[hd(state.operands)]
    {value, _} =  event.value
                  |> hd
                  |> Integer.parse # TODO somehow process based on needed type

    processed_event = %Event{timestamp: timestamp, value: value, stream_name: state.stream_name}
    {:ok, processed_event}
  end
end
