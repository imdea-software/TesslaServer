defmodule TesslaServer.SpecProcessor.GraphBuilder do
  @moduledoc """
  Takes a Tessla spec and generates a DAG of `TesslaServer.Node` modules which represents the spec
  """

  require Logger

  alias TesslaServer.Node

  @spec build([%{atom => any}]) :: :ok
  def build(spec) when is_list(spec) do
    ids = Enum.map spec, &(&1[:"id"])

    Enum.each spec, fn processor ->
      build_node processor
    end

    Enum.each ids, &Node.subscribe_to_operands(&1)
    :ok
  end

  defp build_node(json = %{nodetype: nodetype, id: id}) do
    Logger.debug("----------------")
    Logger.debug("#{inspect nodetype}, id: #{inspect id}")

    ancestors = get_references json
    options = get_options json

    Logger.debug("operands: #{inspect ancestors}")
    Logger.debug("options: #{inspect options}")

    mod = String.to_atom("Elixir." <> nodetype)
    mod.start id, ancestors, options
  end

  # defp get_ordered_list(spec) when is_list(spec) do
  #   g = :digraph.new([:acyclic])
  #   Enum.each(spec, fn processor ->
  #     :digraph.add_vertex(g, processor[:"@id"])
  #   end)

  #   Enum.each(spec, fn processor ->
  #     id = processor[:"@id"]
  #     references = get_references(processor)
  #     Logger.debug("refs for #{id}:  #{inspect references}")
  #     Enum.each(references, fn ref ->
  #       :digraph.add_edge(g, id, ref)
  #     end)
  #   end)

  #   :digraph_utils.postorder(g)
  # end

  defp get_references(%{operands: ids}), do: ids
  defp get_references(%{}), do: []

  defp get_options(%{options: options}), do: options
  defp get_options(%{}), do: %{}
end
