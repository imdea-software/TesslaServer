defmodule TesslaServer.Computation.Aggregation.SignalMaximum do
  @moduledoc """
  Implements a `Computation` that emits the maximum value ever occured on an Signal Stream
  or a default value if it's bigger than all values occured to that point.

  To do so the `state.operands` list has to be initialized with one id representing the id of
  the signal that should be aggregated over
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation
  use Timex

  def process_event_map(event_map, timestamp, state) do
    new_event = event_map[hd(state.operands)]

    case new_event.type do
      :change ->
        old_max = Map.get state.cache, :maximum, (new_event.value - 1)
        new_max = Enum.max [new_event.value, old_max]

        if new_max > old_max do
          {:ok, %Event{
            stream_id: state.stream_id, timestamp: timestamp, value: new_max, type: output_event_type
          }, %{maximum: new_max}}
        else
          {:progress, state.cache}
        end
      :progress -> {:progress, state.cache}
    end
  end

  def output_event_type, do: :change
end
