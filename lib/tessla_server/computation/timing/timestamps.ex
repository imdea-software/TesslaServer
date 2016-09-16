defmodule TesslaServer.Computation.Timing.Timestamps do
  @moduledoc """
  Implements a `Computation` that emits an Event everytime an input Event is received and has it's timestamp as it's value.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which timestamps should be emitted.
  """

  alias TesslaServer.{GenComputation, Event}

  use GenComputation

  # def perform_computation(timestamp, event_map, state) do
  #   new_event = event_map[hd(state.operands)]
  #   {:ok, %Event{
  #     stream_id: state.stream_id, timestamp: timestamp, value: new_event.timestamp
  #   }}
  # end
end
