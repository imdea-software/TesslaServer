defmodule TesslaServer.Computation.Timing.DelayEventByTime do
  @moduledoc """
  Implements a `Computation` that delays the values of an Eventstream by the amount specified in
  `options` under the key `amount` in microseconds.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State

  use GenComputation
  use Timex

  def init(state) do
    amount = Duration.from_microseconds(state.options[:amount])
    options = Map.merge state.options, %{amount: amount}
    super %{state | options: options}
  end

  def process_event_map(event_map, timestamp, state) do
    new_event = event_map[hd(state.operands)]
    amount = state.options[:amount]
    shifted_timestamp = Duration.add(timestamp, amount)

    case new_event.type do
      :event ->
        output_event = %Event{
          timestamp: shifted_timestamp, value: new_event.value, stream_id: state.stream_id
        }
        {:ok, output_event, %{}}
      :progress ->
        {:progress, shifted_timestamp, %{}}
    end
  end
end
