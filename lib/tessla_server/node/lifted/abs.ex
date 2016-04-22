defmodule TesslaServer.Node.Lifted.Abs do
  @moduledoc """
  Implements a `Node` that computes the absolute value of a stream

  To do so the `state.options` object has to be initialized with the key `:operand1`
  which must be an atom representing the name of the event stream that should be the base for the computation.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  use Node

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
    [ History.get_latest_input_of_stream(state.history, state.options.operand1),
    ] |> Enum.filter(&(!is_nil(&1)))
  end
end
