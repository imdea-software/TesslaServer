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

  def prepare_values(state) do
    event = History.get_latest_input state.history
    {:ok, [event]}
  end

  def process_values(state, events) when length(events) < 1, do: {:ok, :wait}
  def process_values(state, [event]) do
    {value, _} =  event.value
                  |> hd
                  |> Integer.parse # TODO somehow process based on needed type

    processed_event = %{event | value: value, stream_name: state.stream_name}
    {:ok, processed_event}
  end
end
