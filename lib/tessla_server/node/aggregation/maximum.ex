defmodule TesslaServer.Node.Aggregation.Maximum do
  @moduledoc """
  Implements a `Node` that emits the maximum value ever occured on an Event Stream
  or a default value if it's bigger than all values occured to that point.

  To do so the `state.operands` list has to be initialized with one atom representing the name of
  the stream that should be aggregated over and the `options` map has to have a key `default`
  which should hold the default value.
  """

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  use Node
  use Timex

  def process_events(timestamp, event_map, state) do
    op1 = hd(state.operands)
    new_event = event_map[op1]
    current_event = EventStream.event_at(state.history.output, timestamp)
    if new_event.value > current_event.value do
      output_event = %Event{
        stream_name: state.stream_name, timestamp: new_event.timestamp, value: new_event.value
      }
      {:ok, updated_history} = History.update_output(state.history, output_event)
      %{state |
        history: updated_history
      }
    else
      %{state | history: History.progress_output(state.history, timestamp)}
    end
  end

  def init_output(state) do
    default_value = state.options[:default]
    default_event = %Event{stream_name: state.stream_name, value: default_value}

    {:ok, history} = History.update_output(state.history, default_event)
    history.output
  end
end
