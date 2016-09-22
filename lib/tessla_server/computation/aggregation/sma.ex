defmodule TesslaServer.Computation.Aggregation.Sma do
  @moduledoc """
  Implements a `Computation` that emits an Event with the simple moving average 
  of the last x input events every time a new Event is received.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which events should be the base for the computation and the options map has to hold a key
  `count` specifying the amount of Events which the average should be formed over.
  """

  alias TesslaServer.{GenComputation, Event, Registry}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    new_event = event_map[hd(state.operands)]

    case new_event.type do
      :event ->
        count = state.options[:count]
        values = Enum.take state.cache.values, count - 1
        new_values = [new_event.value | values]

        average = Enum.sum(new_values) / Enum.count(new_values)

        {:ok,
         %Event{
           stream_id: state.stream_id, timestamp: timestamp, value: average,
           type: output_event_type
         },
          %{values: new_values}
        }
      :progress -> {:progress, state.cache}
    end
  end

  def init_cache(state) do
    %{values: []}
  end
end
