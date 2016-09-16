defmodule TesslaServer.Computation.Filter.IfThenElse do
  @moduledoc """
  Implements a `Computation` that emits a Signal with the value of the second input Signal if the first
  boolean Signal is `true` or with the value of the third signal otherwise.

  To do so the `state.operands` list has to be initialized with three integers, the first specifying
  the boolean Signal acting as the condition and the second and third specifying the signals which
  values should be taken.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  # def perform_computation(timestamp, event_map, state) do
  #   [op1, op2, op3] = state.operands
  #   condition_signal = event_map[op1]
  #   true_signal = event_map[op2]
  #   false_signal = event_map[op3]

  #   cond_changed = (condition_signal.timestamp == timestamp)
  #   true_changed = (true_signal.timestamp == timestamp)
  #   false_changed = (false_signal.timestamp == timestamp)

  #   new_value = if condition_signal.value, do: true_signal.value, else: false_signal.value

  #   cond do
  #     cond_changed ->
  #       {:ok, %Event{
  #         stream_id: state.stream_id,
  #         timestamp: timestamp,
  #         value: new_value
  #       }}
  #     true_changed and condition_signal.value ->
  #       {:ok, %Event{
  #         stream_id: state.stream_id, timestamp: timestamp, value: new_value
  #       }}
  #     false_changed and !condition_signal.value ->
  #       {:ok, %Event{
  #         stream_id: state.stream_id, timestamp: timestamp, value: new_value
  #       }}
  #     true -> :wait
  #   end
  # end

  # def output_stream_type, do: :signal
end
