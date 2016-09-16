defmodule TesslaServer.Computation.Aggregation.Sma do
  @moduledoc """
  Implements a `Computation` that emits an Event with the simple moving average of the last x input events every time a
  new Event is received.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which events should be the base for the computation and the options map has to hold a key
  `count` specifying the amount of Events which the average should be formed over.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation
  use Timex

  # def perform_computation(timestamp, _, state) do
  #   input = state.history.inputs[hd(state.operands)].events
  #   values = input
  #             |> Enum.take(state.options[:count])
  #             |> Enum.map(&(&1.value))
  #   average = Enum.sum(values) / Enum.count(values)
  #   {:ok, %Event{
  #     stream_id: state.stream_id, timestamp: timestamp, value: average
  #   }}
  # end
end
