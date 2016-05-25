defmodule TesslaServer.Node.Timing.DelaySignalByTime do
  @moduledoc """
  Implements a `Node` that delays the values of a signal Stream by the amount specified in
  `options` under the key `amount` in microseconds.
  Only tested for positive values of amount.
  The output signal will hold the value specified under the key `default` in `state.options` as long as the first value
  is delayed.
  """

  alias TesslaServer.{SimpleNode, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use SimpleNode
  use Timex

  def process_events(timestamp, event_map, state) do
    new_event = event_map[hd(state.operands)]
    delay = Time.from(state.options[:amount], :microseconds)
    delayed_timestamp = Time.add(new_event.timestamp, delay)
    new_output = %Event{
      stream_id: state.stream_id, timestamp: delayed_timestamp, value: new_event.value
    }
    {:ok, history} = History.update_output(state.history, new_output, false)
    {:ok, history} = History.progress_output(history, timestamp)
    %{state | history: history}
  end

  def init_output(state) do
    default_value = state.options[:default]
    default_event = %Event{stream_id: state.stream_id, value: default_value}
    {:ok, stream} = EventStream.add_event(state.history.output, default_event)
    %{stream | type: output_stream_type}
  end

  def output_stream_type, do: :signal
end
