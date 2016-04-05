defmodule TesslaServer.Node do
  @moduledoc """
  Base Module to build new Nodes

  When you want to implement a new Node you should call `use TesslaServer.Node`
  Furthermore you'd have to implement the `prepare_values` and `process_values` functions.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History,State}

  @type on_process :: {:wait, State.t} | {:ok, %{ event: Event.t, state: State.t }}
  @typep prepared_values :: %{ values: [Event.t], state: State.t }

  @callback prepare_values(state: State.t) :: prepared_values
  @callback process_values(prepared_values) :: Node.on_process
  @callback start(%{}) :: String.t

  defmacro __using__(_) do
    quote location: :keep do
      alias TesslaServer.{Node, Event}
      alias TesslaServer.Node.{State, History}
      alias TesslaServer.Event

      import TesslaServer.Registry


      use GenServer
      @behaviour Node

      def start(args) do
        GenServer.start(__MODULE__, args, name: via_tuple(args[:stream_name]))
      end

      @spec init(%{stream_name: atom | String.t, options: %{}}) :: { :ok, State.t }
      def init(args) do
        { :ok,
          %State{stream_name: args[:stream_name], options: args[:options]}
        }
      end

      @spec handle_cast({:process, Event.t}, State.t) :: { :noreply, State.t }
      def handle_cast({:process, event}, state) do
        case process(event, state) do
          {:wait, new_state} -> {:noreply, new_state}
          {:ok, new_state} -> handle_processed(new_state)
        end
      end

      @spec handle_cast({:add_child, String.t}, State.t) :: { :noreply, State.t }
      def handle_cast({:add_child, new_child}, state) do
        # TODO: probably send latest event?
         {:noreply, %{ state | children: [new_child | state.children]}}
      end

      @spec process(Event.t, State.t) :: Node.on_process
      defp process(event, state) do
        processed = %{event: event, state: state}
                    |> update_inputs
                    |> prepare_values
                    |> process_values

        case processed do
          {:wait, new_state} ->
            {:wait, new_state}
          {:ok, map} ->
            {:ok, update_output(map)}
        end
      end

      @spec update_inputs(%{event: Event.t, state: State.t}) :: State.t
      defp update_inputs(%{event: event, state: state}) do
        new_history = History.update_input(state.history, event)
        %{ state | history: new_history }
      end

      @spec update_output(%{ state: State.t, event: Event.t }) :: State.t
      defp update_output(%{ state: state, event: event }) do
        new_history = History.update_output(state.history, event)
        %{ state | history: new_history }
      end

      @spec handle_processed(State.t) :: {:noreply, State.t}
      defp handle_processed(state) do
        IO.puts("output of #{state.stream_name}: #{state.history.output |> hd |> inspect}")
        Enum.each(state.children, &GenServer.cast(via_tuple(&1), {:process, state.history.output |> hd} ))

        { :noreply, state }
      end

      defoverridable [start: 1, update_inputs: 1, update_output: 1, handle_processed: 1,
      handle_cast: 2, init: 1]

    end
  end
end
