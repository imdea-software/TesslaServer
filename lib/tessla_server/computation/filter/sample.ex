defmodule TesslaServer.Computation.Filter.Sample do
  @moduledoc """
  Implements a `Computation` that emits Events with the value of a Signal whenever an input Event is
  received.

  To do so the `state.operands` list has to be initialized with two integers, the first specifying
  the Signal which values should be taken and the second specifying the EventStream acting as the
  sampler.
  This is the same as `TesslaServer.Computation.Filter.IfThen` with swapped operands.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  def process_event_map(event_map, timestamp, state) do
    [op1, op2] = state.operands
    change = event_map[op1]

    change_value = if change && change.type == :change, do: change.value, else: state.cache[:last_value]
    cache = %{last_value: change_value}

    sampler = event_map[op2]
    if sampler && sampler.type == :event do
        {:ok, %Event{
          stream_id: state.stream_id, timestamp: timestamp, value: change_value
        }, cache}
    else
        {:progress, cache}
    end
  end
end
