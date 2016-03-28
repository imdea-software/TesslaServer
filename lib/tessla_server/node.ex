defmodule TesslaServer.Node do
  @moduledoc """
  Base Module to build new Nodes

  When you want to implement a new Node you should call `use TesslaServer.Node`
  Furthermore you'd have to implement the `process` function.
  """

  alias TesslaServer.{Node, Event}
  alias TesslaServer.Node.{History,State}

  @type on_process :: {:wait, State.t} | {:ok, %{ event: Event.t, state: State.t }}
  @typep prepared_values :: %{ values: [Event.t], state: State.t }

  @callback prepare_values(state: State.t) :: prepared_values
  @callback process_values(prepared_values) :: Node.on_process

  defmacro __using__(_) do
    quote do
      alias TesslaServer.{Node, Event}
      alias TesslaServer.Node.{State, History}
      alias TesslaServer.Event


      use GenServer
      @behaviour Node

      @spec init(%{children: [pid], stream_name: atom, options: %{}}) :: { :ok, State.t }
      def init(args) do
        { :ok,
          %State{children: args[:children], stream_name: args[:stream_name], options: args[:options]}
        }
      end

      @spec handle_cast({:process, Event.t}, State.t) :: { :noreply, State.t }
      def handle_cast({:process, event}, state) do
        case process(event, state) do
          {:wait, new_state} -> {:noreply, new_state}
          {:ok, new_state} -> handle_processed(new_state)
        end
      end

      @spec process(Event.t, State.t) :: Node.on_process
      defp process(event, state) do
        processed = %{event: event, state: state}
                    |> update_inputs
                    |> prepare_values
                    |> process_values

        case processed do
          {:wait, new_state} -> 
            IO.puts("wait")
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
        Enum.each(state.children, &GenServer.cast(&1, {:process, state.history.output |> hd} ))
        { :noreply, state }
      end
    end
  end
end
