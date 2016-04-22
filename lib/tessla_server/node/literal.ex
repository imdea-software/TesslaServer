defmodule TesslaServer.Node.Literal do
  @moduledoc """
  Represents a Literal
  """

  alias TesslaServer.{Event, Node}
  import TesslaServer.Registry, only: [via_tuple: 1]

  defstruct children: [], value: nil, name: nil
  @type t :: %__MODULE__{name: String.t, value: any, children: [String.t]}

  use GenServer

  def init(args) do
    {:ok, %__MODULE__{name: args[:name], value: args[:value]}}
  end

  def handle_cast(:update, state) do
    literal = %Event{value: state.value, stream_name: state.name}
    Enum.each(state.children, &Node.send_event(&1, literal))
    { :noreply, state }
  end

  @spec handle_cast({:add_child, String.t}, State.t) :: { :noreply, State.t }
  def handle_cast({:add_child, new_child}, state) do
    new_state = %{ state | children: [new_child | state.children]}
    event = %Event{value: state.value, stream_name: state.name}
    Node.send_event(new_child, event)
    {:noreply, new_state}
  end


  def start(defaults) do
    GenServer.start(__MODULE__, defaults, name: via_tuple(defaults[:name]))
  end
end
