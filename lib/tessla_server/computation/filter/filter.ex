defmodule TesslaServer.Computation.Filter.Filter do
  @moduledoc """
  Implements a `Computation` that filters an event stream by the value of a boolean Signal.

  To do so the `state.operands` list has to be initialized with two integers, the first specifying
  the EventStream to be filtered and the second the boolean Signal that is the filter.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    [op1, op2] = state.operands

    new_event = event_map[op1]
    filter_event = event_map[op2]

    filter = if filter_event && filter_event.type != :progress do
      filter_event.value
    else
      state.cache[:filter]
    end

    cond do
      !filter -> {:progress, %{filter: false}}
      is_nil new_event -> {:progress, %{filter: filter}}
      new_event.type == :progress -> {:progress, %{filter: filter}}
      true ->
        {:ok,
         %Event{stream_id: state.stream_id, value: new_event.value, timestamp: timestamp
        }, %{filter: filter}}
    end
  end
end
