defmodule TesslaServer.Node.Monitors.Monitor do
  @moduledoc """
  Implements an Monitor based on multiple inputs, that are used in the LTL expression and a clock.
  state.options has to hold the id of the clock, the states, the initial state as `current_state`
  and the transitions.
  """

  alias TesslaServer.SimpleNode

  use SimpleNode

  def process_events(timestamp, event_map, state = %{options: options}) do
    tick = event_map[options[:clock]]
    if !tick || tick.timestamp != timestamp do
      {:ok, updated_history} = History.progress_output(state.history, timestamp)
      %{state | history: updated_history}
    else
      transitions = transitions_from_state(options[:transitions], options[:current_state])
      values = values_from_inputs(event_map)
      transition = active_transition(transitions, values)
      # transition = active_transition(transitions, event_map)
      state
    end
  end

  def output_stream_type, do: :events

  defp transitions_from_state(all_transitions, current_state) do
    Enum.filter all_transitions, fn transition ->
      transition[:current] == current_state
    end
  end

  defp values_from_inputs(streams) do
    Enum.map streams, fn {id, event} ->
      {id, event.value}
    end
  end

  defp active_transition(transitions, values) do
    
  end
end
