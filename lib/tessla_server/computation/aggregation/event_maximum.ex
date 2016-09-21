defmodule TesslaServer.Computation.Aggregation.EventMaximum do
  @moduledoc """
  Implements a `Computation` that emits the maximum value ever occured on an Event Stream
  or a default value if it's bigger than all values occured to that point.

  To do so the `state.operands` list has to be initialized with one id representing the id of
  the stream that should be aggregated over and the `options` map has to have a key `default`
  which should hold the default value.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation
  use Timex

  # def perform_computation(timestamp, event_map, state) do
  #   op1 = hd(state.operands)
  #   new_event = event_map[op1]
  #   current_event = EventStream.event_at(state.history.output, timestamp)
  #   if new_event.value > current_event.value do
  #     {:ok, %Event{
  #       stream_id: state.stream_id, timestamp: new_event.timestamp, value: new_event.value
  #     }}
  #   else
  #     :wait
  #   end
  # end

  # def init_output(state) do
  #   state.history
  #   # default_value = state.options[:default]
  #   # default_event = %Event{stream_id: state.stream_id, value: default_value}

  #   # {:ok, history} = History.update_output(state.history, default_event)
  #   # %{history.output | type: output_stream_type}
  # end

  # def output_stream_type, do: :signal
end