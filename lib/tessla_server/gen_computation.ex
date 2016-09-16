defmodule TesslaServer.GenComputation do
  @moduledoc """
  Base Module to work with Modules implementing the GenComputation behaviour.
  Note that Computations should implement specific GenServer calls, this cant be expressed right now by
  callbacks because the callbacks are allready defined in GenServer.
  Look at the methods below to see which messages are sent to a Computation.
  """

  alias TesslaServer.Event
  alias TesslaServer.Computation.State

  import TesslaServer.Registry

  @type id :: integer
  @type input_queue :: %{id => [Event.t]}
  @type event_map :: %{id => Event.t}

  # @callback start(id, [id], %{}) :: id
  @callback init_inputs([id]) :: %{id => []}
  # @callback init_output(State.t) :: EventStream.t
  # @callback output_stream_type :: EventStream.stream_type

  # @callback prepare_events(timestamp, State.t) :: event_map
  # @callback process_events(timestamp, event_map, State.t) :: State.t
  # @callback perform_computation(timestamp, event_map, State.t) :: Event.t

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
  Returns the latest output of the specified Computation
  """
  @spec get_latest_output(id) :: Event.t | nil
  def get_latest_output(id) do
    GenServer.call(via_tuple(id), :get_latest_output)
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
      use Timex

      alias TesslaServer.{GenComputation, Event, Output}
      alias TesslaServer.Computation.State

      import TesslaServer.Registry

      use GenServer
      @behaviour GenComputation

      def start(id, operands, options \\ %{}) do
        state = %State{stream_id: id, operands: operands, options: options}
        {:ok, pid} = GenServer.start(__MODULE__, state, name: via_tuple(id))
        id
      end

      def init(state) do
        inputs = init_inputs(state.operands)
        initialized_state = %{state | inputs: inputs}
        {:ok, initialized_state}
      end

      @spec handle_call(:get_latest_output, pid, State.t) :: {:reply, nil | Event.t, State.t}
      def handle_call(:get_latest_output, _, state = %{output: []}), do: {:reply, nil, state}
      def handle_call(:get_latest_output, _, state = %{output: [event | _]}) do
        {:reply, event, state}
      end

      @spec handle_cast({:process, Event.t}, State.t) :: {:noreply, State.t}
      def handle_cast({:process, event}, state) do
        updated_inputs = Map.update! state.inputs, event.stream_id, fn queue ->
          queue ++ [event]
        end

        updated_state = progress %{state | inputs: updated_inputs}
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
        IO.puts(inspect(state))
        input_empty = state.inputs
                      |> Map.values
                      |> Enum.any?(&Enum.empty?(&1))

        if input_empty do
          state
        else
          state.inputs
          |> extract_event_map
          state
        end
      end

      @spec extract_event_map(GenComputation.input_queue) :: GenComputation.event_map
      defp extract_event_map(queue) do
        with events <- Map.values(queue),
        heads <- Enum.map(events, &hd/1),
        timestamps <- Enum.map(heads, &(&1.timestamp)),
        minimal_time <- Enum.min(timestamps),
        events_at_min <- Enum.filter(heads, &Timex.equal?(&1.timestamp, minimal_time)),
        event_tuples <- Enum.map(events_at_min, &({&1.stream_id, &1})),
        do: Map.new(event_tuples)
      end

      def init_inputs(ids) do
        ids
        |> Enum.map(&({&1, []}))
        |> Map.new
      end

      def output_stream_type, do: :events

      defoverridable init: 1, init_inputs: 1, output_stream_type: 0
      # defoverridable [start: 3, prepare_events: 2, process_events: 3,
       #  perform_computation: 3, handle_cast: 2, handle_call: 3, init: 1, init_inputs: 1,
       #  init_output: 1, output_stream_type: 0
       # ]
    end
  end
end
