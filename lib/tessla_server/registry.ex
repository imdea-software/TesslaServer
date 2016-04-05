defmodule TesslaServer.Registry do
  @moduledoc """
  Helper functions for node registration
  """

  def via_tuple(name), do: {:via, :gproc, gproc_tuple(name)}

  def get_pid(key), do: :gproc.lookup_pid gproc_tuple(key)

  defp gproc_tuple(name) when is_atom(name), do: {:n, :l, Atom.to_string name}
  defp gproc_tuple(name) when is_binary(name), do: {:n, :l, name}
end
