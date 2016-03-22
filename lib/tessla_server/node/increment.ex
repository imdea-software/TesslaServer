defmodule TesslaServer.Node.Increment do
  @moduledoc """
  Implements a `Node` that increments an event stream by a given number.

  This number has to be the value of the key `:increment` in `state.options`
  """

  use TesslaServer.Node

  @spec process(Event.t, State.t) :: Node.on_process
  def process(event, state) do
    { :ok, 
      %Event{
        value: event.value + state.options[:increment], 
        stream_name: state.stream_name,
        timestamp: event.timestamp
      }
    }
  end
end
