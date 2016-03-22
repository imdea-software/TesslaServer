defmodule TesslaServer.Node do
  @moduledoc """
  Base Module to build new Nodes
  
  When you want to implement a new Node you should call `use TesslaServer.Node`
  Furthermore you'd have to implement the `process` function.
  """

  alias TesslaServer.Event
  alias TesslaServer.Node.{History,State}

  @type on_process :: :wait | {:ok, Event.t}

  @callback process(Event.t, State.t) :: on_process

  defmacro __using__(_) do
    quote do
      alias TesslaServer.Node
      alias TesslaServer.Node.{State, History}
      alias TesslaServer.Event


      use GenServer
      @behaviour Node

      @spec init(%{children: [pid], stream_name: atom, options: %{}}) :: { :ok, TesslaServer.Node.State.t }
      def init(args) do
        { :ok,
          %State{children: args[:children], stream_name: args[:stream_name], options: args[:options]}
        }
      end

      @spec handle_cast({:process, TesslaServer.Event.t}, TesslaServer.Node.State.t) :: { :noreply, TesslaServer.Node.State.t }
      def handle_cast({:process, event}, state) do
        new_history = History.update_input(state.history, event)
        case process(event, state) do
          :wait -> {:noreply, %{ state | history: new_history }}
          {:ok, processed} -> handle_processed(new_history, state, processed)
        end
      end

      @spec handle_processed(TesslaServer.Node.History.t, TesslaServer.Node.State.t, TesslaServer.Event.t) :: {:noreply, TesslaServer.Node.State.t}
      defp handle_processed(history, state, processed) do
        IO.puts("output of #{state.stream_name}: #{inspect(processed.value)}")
        new_history = History.update_output(history, processed)
        newState = %{ state | history: new_history }
        Enum.each(state.children, &GenServer.cast(&1, {:process, processed} ))
        { :noreply, newState }
      end
    end
  end
end
