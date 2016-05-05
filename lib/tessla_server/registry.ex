defmodule TesslaServer.Registry do
  @moduledoc """
  Helper functions for node registration
  """

  def via_tuple(id), do: {:via, :gproc, gproc_tuple(id)}

  def get_pid(key), do: :gproc.lookup_pid gproc_tuple(key)

  def gproc_tuple(id) when is_integer(id), do: {:n, :l, id}
end
