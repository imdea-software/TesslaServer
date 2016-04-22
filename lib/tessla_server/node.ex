defmodule TesslaServer.Node do
  @moduledoc """
  Base Module to build new Nodes

  When you want to implement a new Node you should call `use TesslaServer.Node`
  Furthermore you'd have to implement the `prepare_values` and `process_values` functions.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History, State}

  import TesslaServer.Registry

  @type on_process :: {:ok, :wait} | {:ok, Event.t}
  @type name :: atom | String.t

  @callback prepare_values(state: State.t) :: {:ok, [Event.t]}
  @callback process_values(State.t, [Event.t]) :: Node.on_process
  @callback start(%{stream_name: atom | String.t}) :: atom | String.t
  # TODO Update inputs
  # TODO Update output
  @callback will_add_child(State.t, name) :: boolean

  @doc """
  Sends a new `Event` to the `Node` that is registered with `name` to process it
  """
  @spec send_event(name, Event.t) :: :ok
  def send_event(name, event) do
    GenServer.cast(via_tuple(name), {:process, event})
  end

  @doc """
  Gets the `State` of the `Node` that is registered under `name`
  """
  @spec get_history(name) :: State.t
  def get_history(name) do
    GenServer.call(via_tuple(name), :get_history)
  end

  @doc """
  Returns the latest output of the named Node
  """
  @spec get_latest_output(name) :: any
  def get_latest_output(name) do
    GenServer.call(via_tuple(name), :get_latest_output)
  end

  @doc """
  Adds a named child to the named `Node`
  """
  @spec add_child(name, name) :: :ok
  def add_child(parent, child) do
    GenServer.cast(via_tuple(parent), {:add_child, child})
  end

  defmacro __using__(_) do
    quote location: :keep do
      alias TesslaServer.{Node, Event}
      alias TesslaServer.Node.{State, History}
      alias TesslaServer.Event

      import TesslaServer.Registry


      use GenServer
      @behaviour Node

      def start(args) do
        name = args[:stream_name]
        GenServer.start(__MODULE__, args, name: via_tuple(name))
        name
      end

      @spec init(%{stream_name: atom | String.t, options: %{}}) :: { :ok, State.t }
      def init(args) do
        { :ok,
          %State{stream_name: args[:stream_name], options: args[:options]}
        }
      end

      @spec handle_call(:get_history, pid, State.t) :: {:reply}
      def handle_call(:get_history, _,state) do
        {:reply, state.history, state}
      end

      @spec handle_call(:get_latest_output, pid,State.t) :: {:reply, any, State.t}
      def handle_call(:get_latest_output, _,state) do
        {:reply, History.get_latest_output(state.history), state}
      end

      @spec handle_cast({:process, Event.t}, State.t) :: { :noreply, State.t }
      def handle_cast({:process, event}, state) do
        case process(event, state) do
          {:wait, new_state} -> {:noreply, new_state}
          {:ok, new_state} -> handle_new_output(new_state)
        end
      end

      @spec handle_cast({:add_child, String.t}, State.t) :: { :noreply, State.t }
      def handle_cast({:add_child, new_child}, state) do
        case will_add_child(state, new_child) do
          true -> {:noreply, %{ state | children: [new_child | state.children]}}
          false -> {:noreply, state}
        end
      end


      def will_add_child(_, _), do: true

      @spec process(Event.t, State.t) :: State.t
      defp process(event, state) do
          with {:ok, updated_input} <- update_inputs(state, event),
               {:ok, prepared_values} <- prepare_values(updated_input),
               {:ok, processed} <- process_values(updated_input, prepared_values),
            do: update_output(updated_input, processed)
      end

      @spec update_inputs(State.t, Event.t) :: {:ok, State.t}
      defp update_inputs(state, event) do
        new_history = History.update_input(state.history, event)
        {:ok, %{ state | history: new_history }}
      end

      @spec update_output(State.t, :wait | Event.t) :: {:ok | :wait, State.t}
      defp update_output(state, :wait), do: {:wait, state}
      defp update_output(state, event) do
        new_history = History.update_output(state.history, event)
        {:ok, %{ state | history: new_history }}
      end

      @spec handle_new_output(State.t) :: {:noreply, State.t}
      defp handle_new_output(state) do
        event = state.history.output |> hd
        value = event.value
        timestamp = event.timestamp

        format(state.stream_name, timestamp, value)
        |> IO.puts


        Enum.each(state.children, &Node.send_event(&1, event))

        { :noreply, state }
      end

      defp format(name, timestamp, value) do
        header = ~w(stream time value)
        TableRex.quick_render!([[name, inspect(timestamp), value]], header)
      end

      defoverridable [start: 1, update_inputs: 2, update_output: 2, handle_new_output: 1,
       handle_cast: 2, handle_call: 3, init: 1, will_add_child: 2]

    end
  end
end
