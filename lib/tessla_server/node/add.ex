defmodule TesslaServer.Node.Add do
  @moduledoc """
  Implements a `Node` that adds two event streams

  To do so the `state.options` object has to be initialized with the keys `:summand1` and `:summand2`,
  which must be atoms representing the names of the event streams that should be summed.
  """

  alias TesslaServer.{Node,Event}
  alias TesslaServer.Node.{History, State}

  use Node

  @spec prepare_values(State.t) :: %{values: [Event.t], state: State.t}
  def prepare_values(state) do
    summands = get_summands(state)
    IO.puts("Summands: #{inspect(summands)}")
    %{values: summands, state: state}
  end

  @spec process_values(%{ values: [Event.t], state: State.t }) :: Node.on_process
  def process_values(%{values: values, state: state}) when length(values) < 2, do: {:wait, state}
  def process_values(%{values: values, state: state}) do
    value = List.foldl(values, 0, &(&1.value + &2))
    event = History.get_latest_input(state.history)
    processed_event = %{event | value: value, stream_name: state.stream_name}
    {:ok, %{event: processed_event, state: state}}
  end


  @spec get_summands(State.t) :: [Event.t]
  defp get_summands(state) do
    [ History.get_latest_input_of_stream(state.history, state.options.summand1),
      History.get_latest_input_of_stream(state.history, state.options.summand2)
    ] |> Enum.filter(&(!is_nil(&1)))
  end
end
