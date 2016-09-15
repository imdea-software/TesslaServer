defmodule TesslaServer.GenComputation do
  @moduledoc """
  Base Module to work with Modules implementing the GenComputation behaviour.
  Note that Computations should implement specific GenServer calls, this cant be expressed right now by
  callbacks because the callbacks are allready defined in GenServer.
  Look at the methods below to see which messages are sent to a Computation.
  """

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Computation.State

  import TesslaServer.Registry

  @type id :: integer

  @typep timestamp :: Timex.Duration.t
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
  @spec get_latest_output(id) :: any
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
      alias TesslaServer.{GenComputation, Event, EventStream, Output}
      alias TesslaServer.Computation.{State, History}

      import TesslaServer.Registry

      @typep timestamp :: Timex.Duration.t

      use GenServer
      @behaviour GenComputation

      def start(id, operands, options \\ %{}) do
        state = %State{stream_id: id, operands: operands, options: options}
        {:ok, pid} = GenServer.start(__MODULE__, state, name: via_tuple(id))
        id
      end

      def init(state) do
        inputs = init_inputs(state.operands)
        output = init_output state
        history = %{state.history | output: output, inputs: inputs}
        {:ok, %{state | history: history}}
      end

      @spec handle_call(:get_latest_output, pid, State.t) :: {:reply, Event.t, State.t}
      def handle_call(:get_latest_output, _,state) do
        {:reply, History.latest_output(state.history), state}
      end

      @spec handle_cast({:process, Event.t}, State.t) :: {:noreply, State.t}
      def handle_cast({:process, event}, state) do
        input_stream = state.history.inputs[event.stream_id]
        {:ok, updated_input_stream} = EventStream.add_event(input_stream, event)
        updated_state = update_input_stream(updated_input_stream, state)
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
        GenComputation.update_input_stream(new_child, state.history.output)
        {:noreply, %{state | children: [new_child | state.children]}}
      end

      @spec progress(State.t) :: State.t
      def progress(state) do
        change_timestamps =
          state.history
          |> History.processable_events
          |> Enum.map(&(&1.timestamp))
          |> Enum.sort
          |> Enum.uniq
        # All timestamps of events between progressed_to and min time of all inputs

        new_state = do_progress(state, change_timestamps)

        old_progress = state.history.output.progressed_to
        new_progress = new_state.history.output.progressed_to
        output = new_state.history.output

        new_outputs =
          output
          |> EventStream.events_in_timeslot(old_progress, new_progress)
          |> Enum.sort_by(&(&1.timestamp))

        if new_progress > old_progress do
          Output.log_new_progress(state.stream_id, new_progress)
          Output.log_new_outputs(state.stream_id, new_outputs)
          Enum.each(new_state.children, &GenComputation.update_input_stream(&1, new_state.history.output))
        end

        new_state
      end

      @spec do_progress(State.t, [timestamp]) :: State.t
      defp do_progress(state, []) do
        {:ok, progressed_history} = History.progress_output(state.history)
        %{state | history: progressed_history}
      end
      defp do_progress(state, [:literal | tail]), do: do_progress(state, [{0, 0, 1} | tail])
      defp do_progress(state, [at | next]) when is_tuple(at) do
        events = prepare_events(at, state)
        updated_state  = process_events(at, events, state)

        do_progress(updated_state, next)
      end

      def prepare_events(at, state) do
        state.history.inputs
        |> Enum.map(fn {id, stream} -> {id, EventStream.event_at(stream, at)} end)
        |> Enum.into(%{})
      end

      def process_events(timestamp, event_map, state) do
        case perform_computation(timestamp, event_map, state) do
          {:ok, new_event} ->
            {:ok, history} = History.update_output(state.history, new_event)
            %{state | history: history}
          :wait ->
            {:ok, updated_history} = History.progress_output(state.history, timestamp)
            %{state | history: updated_history}
        end
      end

      def perform_computation(timestamp, _, state), do: :wait

      def init_inputs(ids) do
        ids
        |> Enum.map(&({&1, %EventStream{id: &1}}))
        |> Map.new
      end

      def init_output(state) do
        %EventStream{id: state.stream_id, type: output_stream_type}
      end

      def output_stream_type, do: :events

      defoverridable [start: 3, prepare_events: 2, process_events: 3,
       perform_computation: 3, handle_cast: 2, handle_call: 3, init: 1, init_inputs: 1,
       init_output: 1, output_stream_type: 0
     ]
    end
  end
end
