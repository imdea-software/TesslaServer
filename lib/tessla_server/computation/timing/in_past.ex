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
    next_false = state.cache[:next_false]
    new_event = event_map[hd(state.operands)]

    false_needed = !!next_false && Duration.to_erl(next_false) < Duration.to_erl(timestamp)
    true_needed = new_event.type == :event && (!next_false || false_needed)

    {produced_changes, cache} = produce_changes false_needed, true_needed, next_false, timestamp, state

    updated_cache = if new_event.type == :event && !false_needed do
      %{next_false: Duration.add(new_event.timestamp, Duration.from_microseconds(state.options[:amount]))}
    else
      cache
    end

    if Enum.empty? produced_changes do
      {:progress, updated_cache}
    else
      {:ok, produced_changes, updated_cache}
    end
  end

  @spec produce_changes(boolean, boolean, Duration.t, Duration.t, State.t) :: {[Event.t], %{}}
  def produce_changes(false_needed, true_needed, false_timestamp, true_timestamp, state)
  def produce_changes(true, true, false_timestamp, true_timestamp, state = %{stream_id: id}) do
    # new input event, old progress was within amount, generate false and true, set cache to next timestamp
    {[
      false_event(false_timestamp, id), true_event(true_timestamp, id)
    ], %{next_false: Duration.add(true_timestamp, Duration.from_microseconds(state.options[:amount]))}}
  end
  def produce_changes(false, true, _, true_timestamp, state = %{stream_id: id}) do
    # new input event, old progress was already out of amount, generate new true and set cache
    {[
      true_event(true_timestamp, id)
    ], %{next_false: Duration.add(true_timestamp, Duration.from_microseconds(state.options[:amount]))}}
  end
  def produce_changes(true, false, false_timestamp, progress, %{stream_id: id}) do
    # Triggered from progress, new progress is after last event plus amount, insert false, clear cache
    {[
      false_event(false_timestamp, id), progress_event(progress, id)
    ], %{}}
  end
  def produce_changes(false, false, _, _, %{cache: cache}) do
    {[], cache}
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

  defp progress_event(timestamp, id) do
    %Event{
      timestamp: timestamp, stream_id: id, type: :progress
    }
  end
end
