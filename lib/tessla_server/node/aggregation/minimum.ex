defmodule TesslaServer.Node.Aggregation.Minimum do
  @moduledoc """
  Implements a `Node` that emits the minimum value ever occured on an Event Stream
  or a default value if it's smaller than all values occured to that point.

  To do so the `state.options` object has to be initialized with the key `:operand1`
  which must be an atom representing the name of the event stream that should be aggregated over
  and the key `default` which should hold the default value.
  """

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use Node
  use Timex

  def init(args) do
    stream_name = args[:stream_name]
    default_value = args[:options][:default]
    default_event = %Event{stream_name: stream_name, timestamp: Time.zero, value: default_value}
    state = %State{stream_name: stream_name, options: args[:options]}
    history = History.update_output(state.history, default_event)
    {:ok, %{state | history: history}}
  end

  def process_events(timestamp, event_map, state) do
    new_event = event_map[state.options.operand1]
    current_event = EventStream.event_at(state.history.output, timestamp)
    if new_event.value < current_event.value do
      output_event = %Event{
        stream_name: state.stream_name, timestamp: new_event.timestamp, value: new_event.value
      }
      updated_history = History.update_output(state.history, output_event)
      %{state |
        history: updated_history
      }
    else
      %{state | history: History.progress_output(state.history, timestamp)}
    end
  end
end
