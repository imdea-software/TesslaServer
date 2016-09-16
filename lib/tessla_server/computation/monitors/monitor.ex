defmodule TesslaServer.Computation.Monitors.Monitor do
  @moduledoc """
  Implements an Monitor based on multiple inputs, that are used in the LTL expression and a clock.
  state.options has to hold the id of the clock, the states, the initial state as `current_state`
  and the transitions.
  """

  alias TesslaServer.GenComputation

  use GenComputation

  # def process_events(timestamp, event_map, state = %{options: options}) do
  #   clock_id = options[:clock]
  #   tick = event_map[clock_id]
  #   if !tick || tick.timestamp != timestamp do
  #     {:ok, updated_history} = History.progress_output(state.history, timestamp)
  #     %{state | history: updated_history}
  #   else
  #     transitions = transitions_from_state(options[:transitions], options[:current_state])
  #     values = event_map |> Map.delete(clock_id) |> values_from_inputs
  #     transition = transitions |> active_transition(values)
  #     new_monitor_state = transition[:next]
  #     IO.puts inspect new_monitor_state
  #     updated_options = %{options | current_state: new_monitor_state}
  #     output_value = state_label(options[:states], new_monitor_state)
  #     output_event = %Event{stream_id: state.stream_id, value: output_value, timestamp: timestamp}
  #     {:ok, updated_history} = History.update_output(state.history, output_event)

  #     %{state | history: updated_history, options: updated_options}
  #   end
  # end

  # def output_stream_type, do: :events

  # defp transitions_from_state(all_transitions, current_state) do
  #   Enum.filter all_transitions, fn transition ->
  #     transition[:current] == current_state
  #   end
  # end

  # defp values_from_inputs(streams) do
  #   streams
  #   |> Enum.map(fn {id, event} -> {id, event.value} end)
  #   |> Enum.into(%{})
  # end

  # defp active_transition(transitions, values) do
  #   Enum.find transitions, fn transition ->
  #     {truthy, falsy} = Map.split(values, transition[:active])
  #     true_list = Map.values(truthy)
  #     false_list = Map.values(falsy)
  #     Enum.all?(true_list) && !Enum.any?(false_list)
  #   end
  # end

  # defp state_label(labelings, state) do
  #   %{output: output} = Enum.find labelings, fn labeling ->
  #     labeling[:name] == state
  #   end
  #   output
  # end
end
