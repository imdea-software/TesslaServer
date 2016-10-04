defmodule TesslaServer.Computation.Timing.Timestamps do
  @moduledoc """
  Implements a `Computation` that emits an Event everytime an input Event is
  received and has its timestamp as it's value.
  To do so the `state.operands` list has to be initialized with one id representing
  the id of the Event Stream which timestamps should be emitted.
  """

  alias TesslaServer.{GenComputation, Event}

  use GenComputation
  use Timex

  def process_event_map(event_map, timestamp, state) do
    new_event = event_map[hd(state.operands)]
    case new_event.type do
      :event ->
        output_event = %Event{
          timestamp: timestamp, stream_id: state.stream_id,
          value: timestamp
        }
        {:ok, output_event, %{}}
      :progress ->
        {:progress, %{}}
    end
  end

end
