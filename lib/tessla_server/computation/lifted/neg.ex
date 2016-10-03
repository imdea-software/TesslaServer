defmodule TesslaServer.Computation.Lifted.Neg do
  @moduledoc """
  Implements a `Computation` that computes the negative value of a Signal.

  To do so the `state.operands` list has to be initialized with one integer which is equal to
  the `id` of the stream that should be the base of the computation.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    new_event = event_map[hd(state.operands)]

    case new_event.type do
      :change ->
        {:ok,
         %Event{
           stream_id: state.stream_id, timestamp: timestamp,
           value: -new_event.value, type: output_event_type
         },
          state.cache
        }
      :progress -> {:progress, state.cache}
    end
  end

  def output_event_type, do: :change
end
