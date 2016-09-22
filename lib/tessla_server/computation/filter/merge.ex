defmodule TesslaServer.Computation.Filter.Merge do
  @moduledoc """
  Implements a `Computation` that merges two event streams.
  The first specified stream takes presedence over the second, meaning if on both streams
  an event happens at the same time, the value of the first will be used.

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the two streams that are the base of the computation.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    [op1, op2] = state.operands
    event1 = event_map[op1]
    event2 = event_map[op2]

    cond do
      event1 && event1.type == :event ->
        {:ok, %Event{value: event1.value, timestamp: timestamp}, %{}}
      event2 && event2.type == :event ->
        {:ok, %Event{value: event2.value, timestamp: timestamp}, %{}}
      true ->
        {:progress, %{}}
    end
  end
end
