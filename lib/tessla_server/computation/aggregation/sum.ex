defmodule TesslaServer.Computation.Aggregation.Sum do
  @moduledoc """
  Implements a `Computation` that emits a Signal holding the summed value of all events happened on the
  input EventStream.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the Event Stream which events' values should be summed.
  """

  alias TesslaServer.{GenComputation, Event, Registry}
  alias TesslaServer.Computation.State

  use GenComputation

  def init(state) do
    Registry.subscribe_to :source
    super state
  end

  def init_cache(state) do
    %{sum: 0}
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
        old_sum = Map.get state.cache, :sum
        new_sum = old_sum + new_event.value
        {:ok, 
         %Event{
           stream_id: state.stream_id, timestamp: timestamp,
           value: new_sum, type: output_event_type
         },
          %{sum: new_sum}
        }
      :progress -> {:progress, state.cache}
    end
  end

  def output_event_type, do: :change
end
