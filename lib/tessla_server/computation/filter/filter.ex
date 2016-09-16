defmodule TesslaServer.Computation.Filter.Filter do
  @moduledoc """
  Implements a `Computation` that filters an event stream by the value of a boolean Signal.

  To do so the `state.operands` list has to be initialized with two integers, the first specifying
  the EventStream to be filtered and the second the boolean Signal that is the filter.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  # def perform_computation(timestamp, event_map, state) do
  #   [op1, op2] = state.operands
  #   to_filter = event_map[op1]
  #   filter = event_map[op2]
  #   cond do
  #     !to_filter ->
  #       :wait
  #     !filter ->
  #       :wait
  #     !(to_filter.timestamp == timestamp) ->
  #       :wait
  #     filter.value ->
  #       {:ok, %Event{
  #         stream_id: state.stream_id, timestamp: timestamp, value: to_filter.value
  #       }}
  #     true ->
  #       :wait
  #   end
  # end
end
