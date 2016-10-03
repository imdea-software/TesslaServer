defmodule TesslaServer.Computation.Lifted.SignalAbs do
  @moduledoc """
  Implements a `Computation` that computes the absolute value of a Signal.

  To do so the `state.operands` list has to be initialized with one integer which is equal to
  the `id` of the stream that should be the base of the computation
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state = %{cache: cache}) do
    new_change = event_map[hd(state.operands)]
    new_value = new_change.value

    if new_change.type == :change && abs(new_value) != cache[:last_value] do
      new_cache = %{last_value: abs(new_value)}
      {:ok,
       %Event{
         stream_id: state.stream_id, timestamp: timestamp,
         value: abs(new_value), type: output_event_type
       },
        new_cache
      }
    else
      {:progress, cache}
    end
  end

  def output_event_type, do: :change
end
