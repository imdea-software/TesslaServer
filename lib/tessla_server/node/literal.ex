defmodule TesslaServer.Node.Literal do
  @moduledoc """
  Represents a Literal.
  """

  alias TesslaServer.{Event, Node}
  import TesslaServer.Registry, only: [via_tuple: 1]

  defstruct children: [], value: nil, id: nil
  @type t :: %__MODULE__{id: integer | nil, value: any, children: [integer]}

  use GenServer

  def init(state) do
    {:ok, state}
  end

  @spec handle_cast(:update | {:add_child, String.t}, State.t) :: {:noreply, Literal.t}
  def handle_cast(:update, state) do
    literal = %Event{value: state.value, stream_id: state.id}
    Enum.each(state.children, &Node.send_event(&1, literal))
    {:noreply, state}
  end
  def handle_cast({:add_child, new_child}, state) do
    new_state = %{state | children: [new_child | state.children]}
    event = %Event{value: state.value, stream_id: state.id}
    Node.send_event(new_child, event)
    {:noreply, new_state}
  end

  @spec handle_call(:subscribe_to_operands, GenServer.from, Literal.t) :: {:reply, :ok, Literal.t}
  def handle_call(:subscribe_to_operands, _, state), do: {:reply, :ok, state}

  def start(id, [], %{value: value}) do
    state = %__MODULE__{id: id, value: value}
    GenServer.start(__MODULE__, state, name: via_tuple(id))
  end
end
