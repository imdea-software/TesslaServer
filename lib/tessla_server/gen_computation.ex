defmodule TesslaServer.GenComputation do
  @moduledoc """
  Base Module to work with Modules implementing the GenComputation behaviour.
  Note that Computations should implement specific GenServer calls, this cant be expressed right now by
  callbacks because the callbacks are allready defined in GenServer.
  Look at the methods below to see which messages are sent to a Computation.
  """

  alias TesslaServer.Event
  alias TesslaServer.Computation.{State, InputBuffer}

  import TesslaServer.Registry, only: [via_tuple: 1]

  @type id :: integer | nil
  @typep events :: Event.t | [Event.t]

  @callback process_event_map(InputBuffer.event_map, Duration.t, State.t) ::
        {:ok, events, State.cache} | {:wait, State.cache} | {:progress, State.cache}
  @callback output_event_type :: Event.event_type
  @callback init_input_buffer([GenComputation.id]) :: InputBuffer.t
  @callback init_cache(State.t) :: State.cache
  # @callback init(State.t) :: {:ok, State.t}

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
  @spec add_child(id, id) :: :ok
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
        cache = init_cache state
        initialized_state = %{state | input_buffer: input_buffer, cache: cache}
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
        updated_state = %{state | input_buffer: updated_buffer}

        do_progress to_process, timestamp, updated_state

      end

      defp do_progress(nil, _, state), do: state
      defp do_progress(to_process, timestamp, state) do
        processed = process_event_map to_process, timestamp, state

        updated_cache = case processed do
          {:ok, new_events, cache} when is_list new_events ->
            new_events
            |> Enum.each(&propagate_output(&1, state))
            cache
          {:ok, new_event, cache} ->
            propagate_output new_event, state
            cache
          {:progress, shifted_time, cache} ->
            propagate_progress shifted_time, state
            cache
          {:progress, cache} ->
            propagate_progress timestamp, state
            cache
          {:wait, cache} ->
            cache
        end

        {to_process, timestamp, updated_buffer} = InputBuffer.pop_head state.input_buffer
        updated_state = %{state | input_buffer: updated_buffer, cache: updated_cache}

        do_progress to_process, timestamp, updated_state
      end

      def process_event_map(event_map, timestamp, state) do
        {:progress, state.cache}
      end

      @spec propagate_output(Event.t, State.t) :: :ok
      def propagate_output(event, state) do
        Output.log_new_event state.stream_id, event
        Enum.each state.children, fn id ->
          GenComputation.send_event id, event
        end
      end

      @spec propagate_progress(Duration.t, State.t) :: :ok
      def propagate_progress(timestamp, state) do
        progress_event = %Event{
          type: :progress, stream_id: state.stream_id, timestamp: timestamp
        }
        propagate_output progress_event, state
      end

      def init_input_buffer(ids) do
        InputBuffer.new(ids)
      end

      def init_cache(state), do: %{}

      def output_event_type, do: :event

      defoverridable init: 1, init_input_buffer: 1, init_cache: 1,
      output_event_type: 0, process_event_map: 3
    end
  end
end
