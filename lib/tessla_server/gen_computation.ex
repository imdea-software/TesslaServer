defmodule TesslaServer.GenComputation do
  @moduledoc """
  Base Module to work with Modules implementing the GenComputation behaviour.
  Note that Computations should implement specific GenServer calls, this cant be expressed right now by
  callbacks because the callbacks are allready defined in GenServer.
  Look at the methods below to see which messages are sent to a Computation.
  """

  alias TesslaServer.Event
  alias TesslaServer.Computation.{State, InputBuffer}

  import TesslaServer.Registry

  @type id :: integer | nil

  @callback init_input_buffer([id]) :: InputBuffer.t

  @doc """
  Sends a new `Event` to the `Computation` that is registered with `id` to process it
  """
  @spec send_event(id, Event.t) :: :ok
  def send_event(id, event) do
    GenServer.cast(via_tuple(id), {:process, event})
  end

  @doc """
  Stops a `Computation` and unregisters its id from `gproc`
  """
  @spec stop(id) :: :ok
  def stop(id) do
    GenServer.stop via_tuple id
  end

  @doc """
  Adds a new child to the specified `Computation`
  """
  @spec add_child(id | nil, id) :: :ok
  def add_child(nil, _), do: :ok
  def add_child(parent, child) do
    GenServer.cast(via_tuple(parent), {:add_child, child})
  end

  @doc """
  Subscribes the `Computation` specified by `id` to all `Computation` it is a descendant of.
  """
  @spec subscribe_to_operands(id) :: :ok
  def subscribe_to_operands(id) do
    GenServer.call(via_tuple(id), :subscribe_to_operands)
  end


  defmacro __using__(_) do
    quote location: :keep do
      alias TesslaServer.{GenComputation, Event, Output}
      alias TesslaServer.Computation.{State, InputBuffer}

      import TesslaServer.Registry

      use GenServer
      @behaviour GenComputation

      def start(id, operands, options \\ %{}) do
        state = %State{stream_id: id, operands: operands, options: options}
        {:ok, pid} = GenServer.start(__MODULE__, state, name: via_tuple(id))
        id
      end

      def init(state) do
        input_buffer = init_input_buffer(state.operands)
        initialized_state = %{state | input_buffer: input_buffer}
        {:ok, initialized_state}
      end

      @spec handle_cast({:process, Event.t}, State.t) :: {:noreply, State.t}
      def handle_cast({:process, event}, state) do
        updated_buffer = InputBuffer.add_event state.input_buffer, event

        updated_state = progress %{state | input_buffer: updated_buffer}
        {:noreply, updated_state}
      end

      @spec handle_call(:subscribe_to_operands, GenServer.from, State.t) :: {:reply, :ok, State.t}
      def handle_call(:subscribe_to_operands, _, state) do
        Enum.each state.operands, fn id ->
          GenComputation.add_child(id, state.stream_id)
        end
        {:reply, :ok, state}
      end

      @spec handle_cast({:add_child, String.t}, State.t) :: {:noreply, State.t}
      def handle_cast({:add_child, new_child}, state) do
        {:noreply, %{state | children: [new_child | state.children]}}
      end

      @spec progress(State.t) :: State.t
      def progress(state) do
          {to_process, timestamp, updated_buffer} = InputBuffer.pop_head state.input_buffer
          process_event_map to_process, timestamp, state
          %{state | input_buffer: updated_buffer}
      end

      def process_event_map(nil, _, _), do: :wait
      def process_event_map(event_map, timestamp, state) do
        propagate_output %Event{stream_id: state.stream_id, timestamp: timestamp}, state
      end

      def propagate_output(event, state) do
        Output.log_new_event state.stream_id, event
        Enum.each state.children, fn id ->
          GenComputation.send_event id, event
        end
      end

      def init_input_buffer(ids) do
        InputBuffer.new(ids)
      end

      def output_stream_type, do: :events

      defoverridable init: 1, init_input_buffer: 1, output_stream_type: 0
    end
  end
end
