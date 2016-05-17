defmodule TesslaServer.Node do
  @moduledoc """
  Base Module to build new Nodes

  When you want to implement a new Node you should call `use TesslaServer.Node`
  Furthermore you'd have to implement the `prepare_values` and `process_values` functions.
  """

  require Logger

  alias TesslaServer.{Node, Event, EventStream}
  alias TesslaServer.Node.{History, State}

  import TesslaServer.Registry

  @type on_process :: {:ok, :wait} | {:ok, Event.t}
  @type id :: integer
  @typep timestamp :: Timex.Types.timestamp
  @typep event_map :: %{id => Event.t}
  @typep computed_event :: {:ok, Event.t} | :wait

  @callback prepare_events(timestamp, State.t) :: event_map
  @callback process_events(timestamp, event_map, State.t) :: State.t
  @callback perform_computation(timestamp, event_map, State.t) :: computed_event

  @callback start(id, [id], %{}) :: id
  @callback init_inputs([id]) :: %{id => EventStream.t}
  @callback init_output(State.t) :: EventStream.t
  @callback output_stream_type :: EventStream.stream_type

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
  @spec add_child(id, id) :: :ok
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

  defmacro __using__(_) do
    quote location: :keep do
      alias TesslaServer.{Node, Event}
      alias TesslaServer.Node.{State, History}
      alias TesslaServer.Event

      import TesslaServer.Registry


      use GenServer
      @behaviour Node

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

      @spec handle_call(:get_history, pid, State.t) :: {:reply}
      def handle_call(:get_history, _,state) do
        {:reply, state.history, state}
      end

      @spec handle_call(:get_latest_output, pid,State.t) :: {:reply, any, State.t}
      def handle_call(:get_latest_output, _,state) do
        {:reply, History.latest_output(state.history), state}
      end

      @spec handle_cast({:update_input_stream, EventStream.t}, State.t) :: {:noreply, State.t}
      def handle_cast({:update_input_stream, stream}, state) do
        updated_state = update_input_stream(stream, state)
        {:noreply, updated_state}
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
          Node.add_child(id, state.stream_id)
        end
        {:reply, :ok, state}
      end

      @spec handle_cast({:add_child, String.t}, State.t) :: {:noreply, State.t}
      def handle_cast({:add_child, new_child}, state) do
        Node.update_input_stream(new_child, state.history.output)
        {:noreply, %{state | children: [new_child | state.children]}}
      end

      @spec update_input_stream(EventStream.t, State.t) :: State.t
      defp update_input_stream(stream, state) do
        {:ok, new_history} = History.replace_input_stream(state.history, stream)
        new_state = %{state | history: new_history}
        all_inputs_ready = Enum.all?(new_state.history.inputs, fn {_, stream} ->
          stream.progressed_to != {0, 0, 0}
        end)
        if all_inputs_ready do
          progress new_state
        else
          new_state
        end
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
        # IO.puts "id: #{inspect state.stream_id}, change_timestamps: #{inspect change_timestamps}"
        new_state = do_progress(state, change_timestamps)

        old_progress = state.history.output.progressed_to
        new_progress = new_state.history.output.progressed_to
        output = new_state.history.output

        new_outputs =
          output
          |> EventStream.events_in_timeslot(old_progress, new_progress)
          |> Enum.sort_by(&(&1.timestamp))

        # IO.puts "id: #{inspect state.stream_id}, progressed_to: #{inspect new_progress}"

        if new_progress > old_progress do
          Node.log_new_progress(state.stream_id, new_progress)
          Node.log_new_outputs(state.stream_id, new_outputs)
          Enum.each(new_state.children, &Node.update_input_stream(&1, new_state.history.output))
        end

        new_state
      end

      @spec do_progress(State.t, [Timex.Types.timestamp]) :: State.t
      defp do_progress(state, []), do: state
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

  @spec log_new_progress(id, timestamp) :: nil
  def log_new_progress(id, new_progress) do
    Logger.debug "Stream #{id} progressed to #{inspect new_progress}"
  end

  @spec log_new_outputs(id, [Event.t]) :: nil
  def log_new_outputs(_, []), do: nil
  def log_new_outputs(id, events) when is_number(id) do
    Logger.debug ("New outputs of #{id}: \n" <> format(events))
  end

  defp format(events) do
    rows = Enum.map events, fn event ->
      [inspect(event.timestamp), inspect(event.value)]
    end
    header = ~w(time value)
    TableRex.quick_render!(rows, header)
  end

end
