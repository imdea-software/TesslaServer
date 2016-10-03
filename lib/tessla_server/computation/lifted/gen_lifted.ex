defmodule TesslaServer.Computation.Lifted.GenLifted do
  @moduledoc """
  Convenience wrapper for Lifted Computations working on two Signals and combine them somehow.

  If you implement a new Computation that does something similar you should consider
  using this module instead to avoid duplication.

  To use it, just add `use GenLifted, combine_operation: &x, equal_operation: &y` after
  `use GenComputation`.

  `combine_operation` will be used to combine the values of the signals whenever one or both changes.
  `equal_operation` will be used to determine if the new value is equal to the last output.
  When it returns false, a new change will be generated, else a progress event will be generated.

  Note that this module takes care of progress events as inputs.
  """

  defmacro __using__(combine_operation: combine_operation, equal_operation: equal_operation) do
    quote location: :keep do
      alias TesslaServer.Event

      def process_event_map(event_map, timestamp, state) do
        [op1, op2] = state.operands
        change1 = event_map[op1]
        change2 = event_map[op2]

        last_value = state.cache[:last_value]

        {new_value, new_cache} = cond do
          change1 && change2 && change1.type == :change && change2.type == :change ->
            {
              unquote(combine_operation).(change1.value, change2.value),
              %{change1.stream_id => change1.value, change2.stream_id => change2.value}
            }
          change1 && change1.type == :change ->
            value2 = state.cache[op2]
            {
              unquote(combine_operation).(change1.value, value2),
              %{change1.stream_id => change1.value}
            }
          change2 && change2.type == :change ->
            value1 = state.cache[op1]
            {
              unquote(combine_operation).(value1, change2.value),
              %{change2.stream_id => change2.value}
            }
          true ->
            {nil, state.cache}
        end

        if is_nil(new_value) || unquote(equal_operation).(new_value, last_value) do
          updated_cache = Map.merge state.cache, new_cache
          {:progress, updated_cache}
        else
          updated_cache = state.cache
                          |> Map.merge(new_cache)
                          |> Map.merge(%{last_value: new_value})
          {:ok, %Event{
            stream_id: state.stream_id, timestamp: timestamp, value: new_value,
            type: output_event_type
          }, updated_cache}
        end
      end
    end
  end
end
