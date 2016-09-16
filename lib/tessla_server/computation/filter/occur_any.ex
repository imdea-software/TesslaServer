defmodule TesslaServer.Computation.Filter.OccurAny do
  @moduledoc """
  Implements a `Computation` that emits Events whenever one input stream is emitting an Event.

  The `state.operands` list has to hold two integers specifying the ids of the two streams.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  # def perform_computation(timestamp, _, state) do
  #   {:ok, %Event{
  #     stream_id: state.stream_id, timestamp: timestamp
  #   }}
  # end
end
