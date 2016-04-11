defmodule TesslaServer.Source.VariableUpdate do
  @moduledoc """
  Implements a `Source` that emits the most recent value for a variable

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
    channel = "variable_update:#{args[:options][:variable_name]}"
    :gproc.reg({:p, :l, channel})
    { :ok,
      %State{stream_name: args[:stream_name], options: args[:options]}
    }
  end

  @spec prepare_values(State.t) :: %{values: [Event.t], state: State.t}
  def prepare_values(state) do
    value = History.get_latest_input state.history
    %{values: [value], state: state}
  end

  @spec process_values(%{ values: [Event.t], state: State.t }) :: Node.on_process
  def process_values(%{values: values, state: state}) when length(values) < 1, do: {:wait, state}
  def process_values(%{values: [event], state: state}) do
    {value, _} =  event.value
                  |> hd
                  |> Integer.parse # TODO somehow process based on needed type

    event = History.get_latest_input(state.history)
    processed_event = %{event | value: value, stream_name: state.stream_name}
    {:ok, %{event: processed_event, state: state}}
  end
end
