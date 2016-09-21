defmodule TesslaServer.Computation.Timing.InPast do
  @moduledoc """
  Implements a `Computation` that emits a Signal holding the value true whenever
  an event happened on the input in a specified amount of time in the past.
  To do so the `state.operands` list has to be initialized with one id representing
  the id of the Event Stream which should be monitored and `state.options` has to
  hold the key `amount` specifying the timeslot where an event should have happened
  in past in microseconds.
  """

  alias TesslaServer.{GenComputation, Event, Registry}

  use GenComputation
  use Timex

  def init(state) do
    Registry.subscribe_to :source
    super state
  end

  def handle_cast(:start_evaluation, state) do
    first_event = false_event(Duration.zero, state.stream_id)

    Enum.each state.children, fn child ->
      GenComputation.send_event child, first_event
    end
    {:noreply, state}
  end

  def process_event_map(event_map, timestamp, state) do
    # TODO handle progress events
    last_event = state.cache[:last_event]
    new_event = event_map[hd(state.operands)]
    updated_cache = %{last_event: new_event}

    produced_changes = produce_changes last_event, new_event, state

    if produced_changes do
      {:ok, produced_changes, updated_cache}
    else
      {:progress, updated_cache}
    end
  end

  @spec produce_changes(Event.t, Event.t, State.t) :: [Event.t]
  def produce_changes(last_event, new_event, state)
  def produce_changes(nil, new_event, state) do
    [true_event(new_event.timestamp, state.stream_id)]
  end
  def produce_changes(last_event, new_event, state) do
    false_timestamp =
      Duration.add(last_event.timestamp, Duration.from_microseconds(state.options[:amount]))
    changes_needed = Duration.to_erl(false_timestamp) < Duration.to_erl(new_event.timestamp)
    if changes_needed do
      [
        false_event(false_timestamp, state.stream_id),
        true_event(new_event.timestamp, state.stream_id)
      ]
    else
      nil
    end
  end

  def output_event_type, do: :change


  defp false_event(timestamp, id) do
    %Event{
      value: false, timestamp: timestamp, stream_id: id, type: output_event_type
    }
  end

  defp true_event(timestamp, id) do
    %Event{
      value: true, timestamp: timestamp, stream_id: id, type: output_event_type
    }
  end
end
