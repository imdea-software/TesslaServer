defmodule TesslaServer.Source do
  @moduledoc """
  Entry Point for new Events from the monitored Programm

  Distributes Events to subscribers via `gproc`
  """

  def distribute(channel, event) when is_binary(channel) do
    GenServer.cast(subscribe_tuple(channel), {:process, event})
    GenServer.cast(input_clock_tuple, {:progress_stream, nil, event.timestamp})
  end

  defp subscribe_tuple(channel) when is_binary(channel) do
    {:via, :gproc, {:p, :l, channel}}
  end

  defp input_clock_tuple do
    {:via, :gproc, {:p, :l, :tick}}
  end
end
