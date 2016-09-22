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

  def process_event_map(event_map, timestamp, state) do
    [op1, op2, op3] = state.operands
    cache = state.cache

    filter_change = event_map[op1]
    if_change = event_map[op2]
    else_change = event_map[op3]

    filter_value = get_value_for :filter_value, filter_change, cache
    if_value = get_value_for :if_value, if_change, cache
    else_value = get_value_for :else_value, else_change, cache

    last_value = cache[:last_value]

    new_value = if filter_value, do: if_value, else: else_value

    new_cache = %{
      filter_value: filter_value, if_value: if_value,
      else_value: else_value, last_value: new_value
    }

    if new_value == last_value do
      {:progress, new_cache}
    else
      {:ok, %Event{
        stream_id: state.stream_id, timestamp: timestamp, value: new_value, type: output_event_type
      }, new_cache}
    end
  end

  defp get_value_for(operator, nil, cache), do: cache[operator]
  defp get_value_for(operator, %{type: :progress}, cache), do: cache[operator]
  defp get_value_for(_, change, _), do: change.value


  def output_event_type, do: :change
end
