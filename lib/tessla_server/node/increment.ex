defmodule TesslaServer.Node.Increment do
  use TesslaServer.Node

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
