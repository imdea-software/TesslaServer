defmodule TesslaServer.Node.Timing.Delay do
  @moduledoc """
  Implements a `Node` that delays the values of an `EventStream` by the amount specified in
  `options` under the key `amount` in microseconds.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node
  use Timex

  def process_events(_, event_map, state) do
    new_event = event_map[hd(state.operands)]
    delay = Time.from(state.options[:amount], :microseconds)
    timestamp = Time.add(new_event.timestamp, delay)
    new_output = %Event{
      stream_id: state.stream_id, timestamp: timestamp, value: new_event.value
    }
    {:ok, history} = History.update_output(state.history, new_output, false)
    {:ok, history} = History.progress_output(history, new_event.timestamp)
    %{state | history: history}
  end
end
