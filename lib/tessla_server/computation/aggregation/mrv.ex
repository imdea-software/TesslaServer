defmodule TesslaServer.Node.Aggregation.Mrv do
  @moduledoc """
  Implements a `Node` that emits a Signal holding the value of the latest event happened on the input.
  To do so the `state.operands` list has to be initialized with one id representing the id of
  the EventStream which values should be converted into a Signal.
  """

  alias TesslaServer.{SimpleNode, Event}
  alias TesslaServer.Node.{History, State}

  use SimpleNode
  use Timex

  def perform_computation(timestamp, event_map, state) do
    last_event = History.latest_output state.history
    new_event = event_map[hd(state.operands)]
    changed = (last_event.value != new_event.value)
    if changed do
      {:ok, %Event{
        stream_id: state.stream_id, timestamp: timestamp, value: new_event.value
      }}
    else
      :wait
    end
  end

  def init_output(state) do
    default_value = state.options[:default]
    default_event = %Event{stream_id: state.stream_id, value: default_value}

    {:ok, history} = History.update_output(state.history, default_event)
    %{history.output | type: output_stream_type}
  end

  def output_stream_type, do: :signal
end
