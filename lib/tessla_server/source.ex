defmodule TesslaServer.Source do
  @moduledoc """
  Entry Point for new Events from the monitored Programm

  Distributes Events to subscribers via `gproc`
  """

  def distribute(channel, event) when is_binary(channel) do
    GenServer.cast(subscribe_tuple(channel), {:process, event})
  end

  defp subscribe_tuple(channel) when is_binary(channel) do
    {:via, :gproc, {:p, :l, channel}}
  end
end
