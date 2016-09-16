defmodule TesslaServer.Computation.Timing.InPast do
  @moduledoc """
  Implements a `Computation` that emits a Signal holding the value true whenever an event happened on the input in a specified
  amount of time in the past.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which should be monitored and `state.options` has to hold the key `amount` specifying the timeslot
  where an event should have happened in past in microseconds.
  """

  alias TesslaServer.{GenComputation, Event}

  use GenComputation
  use Timex

  # def process_events(timestamp, event_map, state) do
  #   new_input = event_map[hd(state.operands)]
  #   last_input =
  #     History.latest_event_of_input_at(state.history, hd(state.operands), Time.sub(new_input.timestamp, {0, 0, 1}))
  #   last_input = last_input || new_input
  #   last_output = History.latest_output(state.history)

  #   change_timestamp = Time.add(last_input.timestamp, Time.from(state.options[:amount], :microseconds))

  #   {:ok, new_history} = cond do
  #     last_output.value && change_timestamp < new_input.timestamp ->
  #       history = insert_false(state.history, change_timestamp, state.stream_id)
  #       History.update_output(history, true_event(timestamp, state.stream_id))
  #     last_output.value && change_timestamp >= new_input.timestamp ->
  #       History.progress_output(state.history, timestamp)
  #     !last_output.value ->
  #       History.update_output(state.history, true_event(timestamp, state.stream_id))
  #   end
  #   %{state | history: new_history}
  # end

  # def init_output(state) do
  #   default_value = false
  #   default_event = %Event{stream_id: state.stream_id, value: default_value}

  #   {:ok, stream} = EventStream.add_event(state.history.output, default_event)
  #   %{stream | type: :signal}
  # end

  # defp insert_false(history, timestamp, id) do
  #   {:ok, history} = History.update_output(history, false_event(timestamp, id))
  #   history
  # end

  # defp false_event(timestamp, id) do
  #     %Event{
  #       value: false, timestamp: timestamp, stream_id: id
  #     }
  # end
  # defp true_event(timestamp, id) do
  #     %Event{
  #       value: true, timestamp: timestamp, stream_id: id
  #     }
  # end
end
