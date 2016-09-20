defmodule TesslaServer.Registry do
  @moduledoc """
  Helper functions for process registration
  """

  def register(name) do
    :gproc.reg register_tuple name
  end

  def subscribe_to(channel) do
    :gproc.reg subscribe_tuple channel
  end

  def get_pid(key), do: :gproc.lookup_pid register_tuple(key)

  def via_tuple(name, property? \\ :name)
  def via_tuple(name, :name), do: {:via, :gproc, register_tuple name}
  def via_tuple(channel, :channel), do: {:via, :gproc, subscribe_tuple channel}

  defp register_tuple(name), do: {:n, :l, name}

  defp subscribe_tuple(channel), do: {:p, :l, channel}
end
