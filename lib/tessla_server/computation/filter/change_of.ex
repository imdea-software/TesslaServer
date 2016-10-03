defmodule TesslaServer.Computation.Filter.ChangeOf do
  @moduledoc """
  Implements a `Computation` that emits Events with the value of a Signal whenever the Signal changes
  it's value.
  To do so the `state.operands` list has to be initialized with one integer specifying the id of
  the Signal of which the changes should be emitted.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    new_event = event_map[hd(state.operands)]

    case new_event.type do
      :event ->
        {:ok,
         %Event{
           stream_id: state.stream_id, timestamp: timestamp,
           value: new_event.value, type: output_event_type
         },
          state.cache
        }
      :progress -> {:progress, state.cache}
    end
  end
end
