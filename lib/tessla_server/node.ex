defmodule TesslaServer.Node do
  @moduledoc """
  Base Module to work with Modules implementing the Node behaviour.
  Note that nodes should implement specific GenServer calls, this cant be expressed right now by
  callbacks because the callbacks are allready defined in GenServer.
  Look at the methods below to see which messages are sent to a Node.

  The `TesslaServer.SimpleNode` Module can be used as a base for building new Nodes.
  """

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.State

  import TesslaServer.Registry

  @type id :: integer

  @typep timestamp :: Timex.Types.timestamp
  @typep event_map :: %{id => Event.t}
  @typep computed_event :: {:ok, Event.t} | :wait

  @callback start(id, [id], %{}) :: id
  @callback init_inputs([id]) :: %{id => EventStream.t}
  @callback init_output(State.t) :: EventStream.t
  @callback output_stream_type :: EventStream.stream_type

  @callback prepare_events(timestamp, State.t) :: event_map
  @callback process_events(timestamp, event_map, State.t) :: State.t
  @callback perform_computation(timestamp, event_map, State.t) :: computed_event

  @doc """
  Sends a new `Event` to the `Node` that is registered with `id` to process it
  """
  @spec send_event(id, Event.t) :: :ok
  def send_event(id, event) do
    GenServer.cast(via_tuple(id), {:process, event})
  end

  @doc """
  Sends the `Node` specified by `id` an `EventStream.t` so that it can update it's inputs.
  """
  @spec update_input_stream(id, EventStream.t) :: :ok
  def update_input_stream(id, stream) do
    GenServer.cast(via_tuple(id), {:update_input_stream, stream})
  end

  @doc """
  Gets the `State.t` of the `Node` that is registered under `id`
  """
  @spec get_history(id) :: State.t
  def get_history(id) do
    GenServer.call(via_tuple(id), :get_history)
  end

  @doc """
  Stops a `Node` and unregisters it's id from `gproc`
  """
  @spec stop(id) :: :ok
  def stop(id) do
    GenServer.stop via_tuple id
  end

  @doc """
  Returns the latest output of the specified Node
  """
  @spec get_latest_output(id) :: any
  def get_latest_output(id) do
    GenServer.call(via_tuple(id), :get_latest_output)
  end

  @doc """
  Adds a new child to the specifiedied `Node`
  """
  @spec add_child(id | nil, id) :: :ok
  def add_child(nil, _), do: :ok
  def add_child(parent, child) do
    GenServer.cast(via_tuple(parent), {:add_child, child})
  end

  @doc """
  Subscribes the `Node` specified by `id` to all `Nodes` it is a descendant of.
  """
  @spec subscribe_to_operands(id) :: :ok
  def subscribe_to_operands(id) do
    GenServer.call(via_tuple(id), :subscribe_to_operands)
  end
end
