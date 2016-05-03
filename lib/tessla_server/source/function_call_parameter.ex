defmodule TesslaServer.Source.FunctionCallParameter do
  @moduledoc """
  Implements a `Source` that emits a parameter value for a called function

  """

  alias TesslaServer.Node

  use Node

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.State

  def init(args) do
    channel = "function_call:#{args[:options][:function_name]}" |> String.to_atom
    :gproc.reg({:p, :l, channel})
    state = %State{stream_name: args[:stream_name], options: args[:options]}
    inputs = Map.new [{channel, %EventStream{name: channel}}]
    history = %{state.history | output: %EventStream{name: args[:stream_name]}, inputs: inputs}
    {:ok, %{state | history: history}}
  end

  def perform_computation(timestamp, event_map, state) do
    channel = "function_call:#{state.options[:function_name]}" |> String.to_atom
    event = event_map[channel]
    {value, _} =  event.value
                  |> Enum.at(state.options[:param_pos])
                  |> Integer.parse # TODO somehow process based on needed type

    processed_event = %Event{timestamp: timestamp, value: value, stream_name: state.stream_name}
    {:ok, processed_event}
  end
end
