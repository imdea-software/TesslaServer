defmodule TesslaServer.Registry do
  @moduledoc """
  Helper functions for node registration
  """

  def via_tuple(name), do: {:via, :gproc, gproc_tuple(name)}

  def get_pid(key), do: :gproc.lookup_pid gproc_tuple(key)

  def gproc_tuple(name) when is_atom(name), do: {:n, :l, name}
  def gproc_tuple(name) when is_binary(name), do: {:n, :l, String.to_atom name}
end
