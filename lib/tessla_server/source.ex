defmodule TesslaServer.Source do
  @moduledoc """
  Entry Point for new Events from the monitored Programm

  Distributes Events to subscribers via `gproc`
  """

  def distribute(event) do
    GenServer.cast(subscribe_tuple(event.stream_id), {:process, event})
  end

  defp subscribe_tuple(name) do
    {:via, :gproc, {:p, :l, name}}
  end
end
