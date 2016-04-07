defmodule TesslaServer.Source.FunctionCallParameter do
  @moduledoc """
  Implements a `Source` that emits a parameter value for a called function

  """

  alias TesslaServer.Node

  use Node

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  def start(args) do
    GenServer.start(__MODULE__, args, name: via_tuple(args[:stream_name]))
  end

  @spec init(%{stream_name: atom | String.t, options: %{}}) :: { :ok, State.t }
  def init(args) do
    channel = "function_call:#{args[:options][:function_name]}"
    IO.puts channel
    :gproc.reg({:p, :l, channel})
    { :ok,
      %State{stream_name: args[:stream_name], options: args[:options]}
    }
  end

  @spec prepare_values(State.t) :: %{values: [Event.t], state: State.t}
  def prepare_values(state) do
    call = History.get_latest_input state.history
    %{values: [call], state: state}
  end

  @spec process_values(%{ values: [Event.t], state: State.t }) :: Node.on_process
  def process_values(%{values: values, state: state}) when length(values) < 1, do: {:wait, state}
  def process_values(%{values: values, state: state}) do
    event = hd values
    {value, _} =  event.value
                  |> Enum.at(state.options[:param_pos])
                  |> Integer.parse # TODO somehow process based on needed type

    event = History.get_latest_input(state.history)
    processed_event = %{event | value: value, stream_name: state.stream_name}
    {:ok, %{event: processed_event, state: state}}
  end
end
