defmodule TesslaServer.Computation.Lifted.Add do
  @moduledoc """
  Implements a `Computation` that adds two event streams

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the two streams that are the base of the computation.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    cache = Map.merge state.cache, event_map
    [op1, op2] = state.operands
    change1 = cache[op1]
    change2 = cache[op2]

    if change1 && change2 do
      events = [%Event{
        stream_id: state.stream_id, timestamp: timestamp,
        value: change1.value + change2.value, type: output_event_type
      }]
      {:ok, events, cache}
    else
      {:progress, state.cache}
    end
  end

  def output_event_type, do: :change
end
