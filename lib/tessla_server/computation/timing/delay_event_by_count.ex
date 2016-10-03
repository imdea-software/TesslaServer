defmodule TesslaServer.Computation.Timing.DelayEventByCount do
  @moduledoc """
  Implements a `Computation` that delays input events until a later event occurs.
  The Number of events that need to occur must be specified under `count` in `state.options`.
  The Stream that should be delayed should be specified in `state.operands` as the only id in the list.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation
  use Timex

  def init_cache(_) do
    %{buffer: []}
  end

  def process_event_map(event_map, timestamp, state = %{cache: cache}) do
    new_event = event_map[hd(state.operands)]
    buffer = cache[:buffer]
    delay_count = state.options[:count]

    cond do
      length(buffer) == delay_count && new_event.type == :event ->
        [output_value | new_buffer] = buffer ++ [new_event.value]
        output_event = %Event{value: output_value, timestamp: timestamp, stream_id: state.stream_id}
        {:ok, output_event, %{buffer: new_buffer}}
      new_event.type == :event ->
        new_buffer = buffer ++ [new_event.value]
        {:progress, %{buffer: new_buffer}}
      true ->
        {:progress, state.cache}
    end
  end
end
