defmodule TesslaServer.Node.Mul do
  @moduledoc """
  Implements a `Node` that multiplies two event streams
  To do so the `state.options` object has to be initialized with the keys `:operand1` and `:operand2`,
  which must be atoms representing the names of the event streams that should be multiplied.
  """
  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node

  @spec prepare_values(State.t) :: %{values: [Event.t], state: State.t}
  def prepare_values(state) do
    %{values: get_operands(state), state: state}
  end

  @spec process_values(%{ values: [Event.t], state: State.t }) :: Node.on_process
  def process_values(%{values: values, state: state}) when length(values) < 2, do: {:wait, state}
  def process_values(%{values: values, state: state}) do
    [op1 | [op2]] = values
    value = op1.value * op2.value
    event = History.get_latest_input(state.history)
    processed_event = %{event | value: value, stream_name: state.stream_name}
    {:ok, %{event: processed_event, state: state}}
  end


  @spec get_operands(State.t) :: [Event.t]
  defp get_operands(state) do
    [ History.get_latest_input_of_stream(state.history, state.options.operand1),
      History.get_latest_input_of_stream(state.history, state.options.operand2)
    ] |> Enum.filter(&(!is_nil(&1)))
  end
end
