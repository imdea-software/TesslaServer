defmodule TesslaServer.Node.Aggregation.Maximum do
  @moduledoc """
  Implements a `Node` that emits the maximum value ever occured on an Event Stream
  or a default value if it's bigger than all values occured to that point.

  To do so the `state.options` object has to be initialized with the key `:operand1`
  which must be an atom representing the name of the event stream that should be aggregated over
  and the key `default` which should hold the default value.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node
  use Timex

  @spec init(%{stream_name: atom | String.t, options: %{}}) :: { :ok, State.t }
  def init(args) do
    stream_name = args[:stream_name]
    default_value = args[:options][:default]
    default_event = %Event{stream_name: stream_name, timestamp: Time.zero, value: default_value}
    state = %State{ stream_name: stream_name, options: args[:options]}
    history = History.update_output(state.history, default_event)
    { :ok,
      %{state | history: history}
    }
  end


  def will_add_child(state, name) do
    Node.send_event name, History.get_latest_output(state.history)
    true
  end

  def prepare_values(state) do
    {:ok, get_operands(state)}
  end

  def process_values(state, events) when length(events) < 1, do: {:ok, :wait}
  def process_values(state, events) do
    [op1] = events
    value = abs op1.value
    event = op1
    processed_event = %{event | value: value, stream_name: state.stream_name}
    {:ok, processed_event}
  end


  @spec get_operands(State.t) :: [Event.t]
  defp get_operands(state) do
    [ History.get_latest_output(state.history),
      History.get_latest_input_of_stream(state.history, state.options.operand1),
    ] |> Enum.filter(&(!is_nil(&1)))
  end
end
