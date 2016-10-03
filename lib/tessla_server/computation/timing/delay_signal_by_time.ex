defmodule TesslaServer.Computation.Timing.DelaySignalByTime do
  @moduledoc """
  Implements a `Computation` that delays the values of a Signal by the amount specified in
  `options` under the key `amount` in microseconds.
  Only tested for positive values of amount.
  The output signal will hold the value specified under the key `default` in `state.options` as long as the first value
  is delayed.
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
    initial_change = if timestamp == Duration.zero do
        %Event{
          timestamp: Duration.zero, value: state.options[:default],
          stream_id: state.stream_id, type: :change
        }
    end
    new_change = event_map[hd(state.operands)]
    amount = state.options[:amount]
    shifted_timestamp = Duration.add(timestamp, amount)

    case new_change.type do
      :change ->
        output_change = %Event{
          timestamp: shifted_timestamp, value: new_change.value,
          stream_id: state.stream_id, type: :change
        }
        cond do
          initial_change && initial_change.value == new_change.value ->
            progress_event = %Event{
              type: :progress, timestamp: shifted_timestamp, stream_id: state.stream_id
            }
            {:ok, [initial_change, progress_event], %{}}
          initial_change ->
            {:ok, [initial_change, output_change], %{}}
          true ->
            {:ok, output_change, %{}}
        end
      :progress ->
        {:progress, shifted_timestamp, %{}}
    end
  end
end
