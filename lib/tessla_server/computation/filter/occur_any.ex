defmodule TesslaServer.Computation.Filter.OccurAny do
  @moduledoc """
  Implements a `Computation` that emits Events whenever one input stream is emitting an Event.

  The `state.operands` list has to hold two integers specifying the ids of the two streams.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    [op1, op2] = state.operands
    event1 = event_map[op1]
    event2 = event_map[op2]

    event1_happened = event1 && event1.type == :event
    event2_happened = event2 && event2.type == :event

    if event1_happened || event2_happened do
      {:ok, %Event{timestamp: timestamp}, %{}}
    else
      {:progress, %{}}
    end
  end
end
