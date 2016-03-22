defmodule TesslaServer.Node.Add do
  @moduledoc """
  Implements a `Node` that adds two event streams
  
  To do so the `state.options` object has to be initialized with the keys `:summand1` and `:summand2`,
  which must be atoms representing the names of the event streams that should be summed.
  """

  alias TesslaServer.{Node,Event}
  alias TesslaServer.Node.{History, State}

  use Node

  @doc """
  Processes a given `event` by adding it's value to the last value of the other event stream saved in
  `state.history`.
  To do so the keys `:summand1` and `:summand2` have to be present in `state.options`, 
  and the value of one of them has to be the same as `event.stream_name` and the value 
  of the other one has to match a key in `state.history.inputs`

  Returns `:wait` if at least one event stream doesn't have a value until now
  or `{:ok, new_event}` where the new event is computed by adding the two last events of
  the specified event stream.
  """
  @spec process(Event.t, State.t) :: Node.on_process
  def process(event, state) do
    {summand1, summand2} = get_summands(event, state)
    case add(summand1, summand2) do
      nil -> :wait
      x -> {:ok, %Event{value: x, stream_name: state.stream_name, timestamp: event.timestamp}}
    end
  end

  @typep optional_event :: Event.t | nil
  @typep optional_number :: Number | nil

  @spec add(optional_event, optional_event) :: optional_number
  defp add(nil, _), do: nil
  defp add(_, nil), do: nil
  defp add(summand1, summand2) do
    summand1.value + summand2.value
  end

  @spec get_summands(Event.t, State.t) :: {Event.t, Event.t}
  defp get_summands(event, state) do
    name_summand1 = state.options.summand1
    name_summand2 = state.options.summand2
    case event.stream_name do
      ^name_summand1 -> { event, History.get_latest_input_of_stream(state.history, state.options.summand2) }
      ^name_summand2 -> { History.get_latest_input_of_stream(state.history, state.options.summand1), event }
      _ -> raise("Event doesn't match a summand stream")
    end
  end
end
