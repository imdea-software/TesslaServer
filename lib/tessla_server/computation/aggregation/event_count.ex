defmodule TesslaServer.Computation.Aggregation.EventCount do
  @moduledoc """
  Implements a `Computation` that emits a Signal holding the amount of Events happened on an Event
  Stream.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which events should be counted.
  """

  alias TesslaServer.{GenComputation, Event, Registry}
  alias TesslaServer.Computation.State

  use GenComputation

  def init(state) do
    Registry.subscribe_to :source
    super state
  end

  def handle_cast(:start_evaluation, state) do
    first_event = %Event{
      stream_id: state.stream_id, value: 0, type: output_event_type
    }

    Enum.each state.children, fn child ->
      GenComputation.send_event child, first_event
    end
    {:noreply, state}
  end

  def process_event_map(event_map, timestamp, state) do
    new_event = event_map[hd(state.operands)]

    case new_event.type do
      :event ->
        count = Map.get state.cache, :count
        {:ok, %Event{
          stream_id: state.stream_id, timestamp: timestamp, value: count + 1, type: output_event_type
        }, %{count: count + 1}}
      :progress -> {:progress, state.cache}
    end
  end

  def init_cache(_) do
    %{count: 0}
  end

  def output_event_type, do: :change
end
