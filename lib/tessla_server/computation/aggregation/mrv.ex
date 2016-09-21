defmodule TesslaServer.Computation.Aggregation.Mrv do
  @moduledoc """
  Implements a `Computation` that emits a Signal holding the value of the latest event happened on the input.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the EventStream which values should be converted into a Signal and options has to hold
  the initial value under the key `default`.
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
      stream_id: state.stream_id, value: state.cache[:last_value], type: output_event_type
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
        last_value = Map.get state.cache, :last_value
        if new_event.value != last_value do
          {:ok, %Event{
            stream_id: state.stream_id, timestamp: timestamp, value: new_event.value, type: output_event_type
          }, %{last_value: new_event.value}}
        else
          {:progress, state.cache}
        end
      :progress -> {:progress, state.cache}
    end
  end

  def init_cache(state) do
    %{last_value: state.options[:default]}
  end

  def output_event_type, do: :change
end
