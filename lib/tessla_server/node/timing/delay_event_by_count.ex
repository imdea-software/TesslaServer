defmodule TesslaServer.Node.Timing.DelayEventByCount do
  @moduledoc """
  Implements a `Node` that delays input events until a later event occurs.
  The Number of events that need to occur must be specified under `count` in `state.options`.
  The Stream that should be delayed should be specified in `state.operands` as the only id in the list.
  """

  alias TesslaServer.{SimpleNode, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use SimpleNode
  use Timex

  def prepare_events(at, state) do
    stream = state.history.inputs[hd(state.operands)]
    events_before = EventStream.events_in_timeslot(stream, Time.zero, at)
    event = Enum.at(events_before, state.options[:count])
    if event, do: %{event.stream_id => event}, else: %{}
  end

  def process_events(timestamp, event_map, state) when map_size(event_map) == 0 do
    {:ok, history} = History.progress_output(state.history, timestamp)
    %{state | history: history}
  end
  def process_events(timestamp, event_map, state) do
    delayed_event = event_map[hd(state.operands)]
    new_output = %Event{
      stream_id: state.stream_id, timestamp: timestamp, value: delayed_event.value
    }
    {:ok, history} = History.update_output(state.history, new_output)
    %{state | history: history}
  end
end
