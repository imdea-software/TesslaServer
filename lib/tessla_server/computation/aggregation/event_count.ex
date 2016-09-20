defmodule TesslaServer.Computation.Aggregation.EventCount do
  @moduledoc """
  Implements a `Computation` that emits a Signal holding the amount of Events happened on an Event
  Stream.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which events should be counted.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation

  # def perform_computation(timestamp, _, state) do
  #   {:ok, %Event{
  #     stream_id: state.stream_id, timestamp: timestamp, value: last_event.value + 1
  #   }}
  # end

  # def init_output(state) do
  #   default_value = 0
  #   default_event = %Event{stream_id: state.stream_id, value: default_value}

  #   {:ok, history} = History.update_output(state.history, default_event)
  #   %{history.output | type: output_stream_type}
  # end

  # def output_stream_type, do: :signal
end
