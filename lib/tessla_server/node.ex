defmodule TesslaServer.Node do
  alias TesslaServer.Event

  @callback process(Event.t, State.t) :: any

  defmacro __using__(_) do
    quote do
      alias TesslaServer.Node
      alias TesslaServer.Node.State
      alias TesslaServer.Event


      use GenServer
      @behaviour Node

      @spec init(%{children: [pid], options: Keyword.t}) :: { :ok, TesslaServer.Node.State.t }
      def init(args) do
        { :ok,
          %State{children: args[:children], options: args[:options]}
        }
      end

      @spec handle_cast({:process, TesslaServer.Event.t}, TesslaServer.Node.State.t) :: { :noreply, TesslaServer.Node.State.t }
      def handle_cast({:process, event}, state) do
        processed = process(event, state)
        processed_event = %{ event | description: processed }
        newState = %{ state | history: [processed_event | state.history]  }
        Enum.each(state.children, &GenServer.cast(&1, {:process, processed_event} ))
        { :noreply,
          newState
        }
      end
    end
  end
end
