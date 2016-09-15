defmodule TesslaServer.SpecProcessor.GraphBuilder do
  @moduledoc """
  Takes a Tessla spec and generates a DAG of `TesslaServer.GenComputation` modules which represents the spec
  """

  require Logger

  alias TesslaServer.GenComputation

  @spec build([%{atom => any}]) :: [integer]
  def build(spec) when is_list(spec) do
    ids = Enum.map spec, &(&1[:"id"])

    Enum.each spec, fn processor ->
      build_computation processor
    end

    Enum.each ids, &GenComputation.subscribe_to_operands(&1)
    ids
  end

  defp build_computation(json = %{nodetype: computation, id: id}) do
    Logger.debug("----------------")
    Logger.debug("#{inspect Computation}, id: #{inspect id}")

    ancestors = get_references json
    options = get_options json

    Logger.debug("operands: #{inspect ancestors}")
    Logger.debug("options: #{inspect options}")

    mod = String.to_atom("Elixir." <> computation)
    mod.start id, ancestors, options
  end

  defp get_references(%{operands: ids}), do: ids
  defp get_references(%{}), do: []

  defp get_options(%{options: options}), do: options
  defp get_options(%{}), do: %{}
end
