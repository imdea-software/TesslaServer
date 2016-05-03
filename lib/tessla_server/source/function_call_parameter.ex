defmodule TesslaServer.Source.FunctionCallParameter do
  @moduledoc """
  Implements a `Source` that emits a parameter value for a called function

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
                  |> Enum.at(state.options[:param_pos])
                  |> Integer.parse # TODO somehow process based on needed type

    processed_event = %Event{timestamp: timestamp, value: value, stream_name: state.stream_name}
    {:ok, processed_event}
  end
end
