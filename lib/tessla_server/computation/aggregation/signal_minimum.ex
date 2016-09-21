defmodule TesslaServer.Computation.Aggregation.SignalMinimum do
  @moduledoc """
  Implements a `Computation` that emits the minimum value ever occured on an Signal Stream
  or a default value if it's smaller than all values occured to that point.

  To do so the `state.operands` list has to be initialized with one integer representing the id of
  the stream that should be aggregated over and the `options` map has to have a key `default`
  which should hold the default value.
  """


  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation
  use Timex

  def process_event_map(event_map, timestamp, state) do
    new_event = event_map[hd(state.operands)]

    case new_event.type do
      :change ->
        old_min = Map.get state.cache, :minimum, (new_event.value + 1)
        new_min = Enum.min [new_event.value, old_min]

        if new_min < old_min do
          {:ok, %Event{
            stream_id: state.stream_id, timestamp: timestamp, value: new_min, type: output_event_type
          }, %{minimum: new_min}}
        else
          {:progress, state.cache}
        end
      :progress -> {:progress, state.cache}
    end
  end

  def output_event_type, do: :change
end
