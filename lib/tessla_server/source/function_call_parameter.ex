defmodule TesslaServer.Source.FunctionCallParameter do
  @moduledoc """
  Implements a `Source` that emits a parameter value for a called function

  """

  alias TesslaServer.Node

  use Node

  alias TesslaServer.{Node,Event}
  alias TesslaServer.Node.{History, State}

  def start(args) do
    #TODO Register for pub/sub
    GenServer.start(__MODULE__, args, name: via_tuple(args[:stream_name]))
  end

  @spec prepare_values(State.t) :: %{values: [Event.t], state: State.t}
  def prepare_values(state) do

    call = History.get_latest_input state.history
    %{values: [call], state: state}
  end

  @spec process_values(%{ values: [Event.t], state: State.t }) :: Node.on_process
  def process_values(%{values: values, state: state}) when length(values) < 1, do: {:wait, state}
  def process_values(%{values: values, state: state}) do
    call = hd values

    r = ~r/[a-zA-Z0-9:_.-]*\(([^)]*)\)/
    value = Regex.run(r, call.value, capture: :all_but_first)
            |> hd
            |> String.split(",")
            |> Enum.at(state.options[:param_pos])

    event = History.get_latest_input(state.history)
    processed_event = %{event | value: value, stream_name: state.stream_name}
    {:ok, %{event: processed_event, state: state}}
  end
end
