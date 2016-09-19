defmodule TesslaServer.Computation.Literal do
  @moduledoc """
  Represents a Literal.
  """

  alias TesslaServer.{Event, GenComputation}
  import TesslaServer.Registry, only: [via_tuple: 1]

  defstruct children: [], value: nil, id: nil
  @type t :: %__MODULE__{id: GenComputation.id, value: any, children: [GenComputation.id]}

  use GenServer

  def start_literals do
    GenServer.cast {:via, :gproc, {:p, :l, :literals}}, :start_evaluation
  end

  def init(state) do
    :gproc.reg({:p, :l, :literals})
    {:ok, state}
  end

  @spec handle_cast({:add_child, String.t}, Literal.t) :: {:noreply, Literal.t}
  def handle_cast({:add_child, new_child}, state) do
    new_state = %{state | children: [new_child | state.children]}
    {:noreply, new_state}
  end
  def handle_cast(:start_evaluation, state) do
    literal = %Event{value: state.value, stream_id: state.id, timestamp: :literal}
    Enum.each state.children, fn child ->
      GenComputation.send_event child, literal
    end
    {:noreply, state}
  end

  @spec handle_call(:subscribe_to_operands, GenServer.from, Literal.t) :: {:reply, :ok, Literal.t}
  def handle_call(:subscribe_to_operands, _, state), do: {:reply, :ok, state}

  def start(id, [], %{value: value}) do
    state = %__MODULE__{id: id, value: value}
    GenServer.start(__MODULE__, state, name: via_tuple(id))
  end
end
