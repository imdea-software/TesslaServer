defmodule TesslaServer.Source do
  @moduledoc """
  Entry Point for new Events from the monitored Programm

  Distributes Events to subscribers via `gproc`
  """

  alias TesslaServer.Registry

  import Registry, only: [via_tuple: 2]

  def distribute(channel, event) when is_binary(channel) do
    GenServer.cast(via_tuple(channel, :channel), {:process, event})
  end

  def start_evaluation do
    GenServer.cast via_tuple(:source, :channel), :start_evaluation
  end
end
