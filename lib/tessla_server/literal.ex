defmodule TesslaServer.Literal do
  @moduledoc """
  Represents a Literal
  """

  alias TesslaServer.Event
  defstruct children: [], value: nil, name: nil
  @type t :: %__MODULE__{name: String.t, value: any, children: [String.t]}

  use GenServer

  def init(args) do
    {:ok, %__MODULE__{name: args[:name], value: args[:value]}}
  end

  def handle_cast(:update, state) do
    literal = %Event{value: state.value, stream_name: state.name}
    Enum.each(state.children, &GenServer.cast(via_tuple(&1), {:process, literal} ))
    { :noreply, state }
  end

  @spec handle_cast({:add_child, String.t}, State.t) :: { :noreply, State.t }
  def handle_cast(l = {:add_child, new_child}, state) do
    new_state = %{ state | children: [new_child | state.children]}
    event = %Event{value: state.value, stream_name: state.name}
    GenServer.cast(via_tuple(new_child), {:process, event})
    {:noreply, new_state}
  end


  def start(defaults) do
    GenServer.start(__MODULE__, defaults, name: via_tuple(defaults[:name]))
  end

  defp via_tuple(stream_name) do
    {:via, :gproc, {:n, :l, stream_name}}
  end
end
