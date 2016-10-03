defmodule TesslaServer.Computation.Lifted.Add do
  @moduledoc """
  Implements a `Computation` that adds two Signals.

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the two streams that are the base of the computation.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    [op1, op2] = state.operands
    change1 = event_map[op1]
    change2 = event_map[op2]

    last_value = state.cache[:added]

    {new_value, new_cache} = cond do
      change1 && change2 && change1.type == :change && change2.type == :change ->
        {
          change1.value + change2.value,
          %{change1.stream_id => change1.value, change2.stream_id => change2.value}
        }
      change1 && change1.type == :change ->
        value2 = state.cache[op2]
        {
          change1.value + value2,
          %{change1.stream_id => change1.value}
        }
      change2 && change2.type == :change ->
        value1 = state.cache[op1]
        {
          value1 + change2.value,
          %{change2.stream_id => change2.value}
        }
      true ->
        {nil, state.cache}
    end

    if new_value && new_value != last_value do
      updated_cache = state.cache
                      |> Map.merge(new_cache)
                      |> Map.merge(%{added: new_value})
      {:ok, %Event{
        stream_id: state.stream_id, timestamp: timestamp, value: new_value,
        type: output_event_type
      }, updated_cache}
    else
      {:progress, state.cache}
    end
  end

  def output_event_type, do: :change
end
