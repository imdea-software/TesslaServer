defmodule TesslaServer.Source do
  @moduledoc """
  Entry Point for new Events from the monitored Programm

  Distributes Events to subscribers via `gproc`
  """

  alias TesslaServer.Event

  def distribute(channel, value, timestamp) do
    event = %Event{value: value, stream_name: channel, timestamp: timestamp}
    GenServer.cast(subscribe_tuple(event.stream_name), {:process, event})
  end

  defp subscribe_tuple(name) do
    {:via, :gproc, {:p, :l, name}}
  end
end
