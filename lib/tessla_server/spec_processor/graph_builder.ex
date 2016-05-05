defmodule TesslaServer.SpecProcessor.GraphBuilder do
  @moduledoc """
  Takes a Tessla spec and generates a DAG of `TesslaServer.Node` modules which represents the spec
  """

  require Logger

  alias TesslaServer.Node
  alias TesslaServer.Source

  @spec build([%{atom => any}]) :: :ok
  def build(spec) when is_list(spec) do
    list = get_ordered_list spec

    Logger.debug inspect list
    Enum.each list, fn id ->
      processor = Enum.find spec, &(&1[:"@id"] == id)
      build_node processor
    end
    :ok
  end

  defp build_node(json = %{"@type": "dataFlowGraph.node.operation.AddNode"}) do
    id = json[:"@id"]
    Logger.debug("add id: %{inspect id}")

    ancestors = get_references json
    Node.Lifted.Add.start id, ancestors

    add_to_ancestors(id, ancestors)
  end

  defp add_to_ancestors(child, ancestors) do
    Enum.each(ancestors, &(Node.add_child(&1, child)))
    child
  end

  defp get_ordered_list(spec) when is_list(spec) do
    g = :digraph.new([:acyclic])
    Enum.each(spec, fn processor ->
      :digraph.add_vertex(g, processor[:"@id"])
    end)

    Enum.each(spec, fn processor ->
      id = processor[:"@id"]
      references = get_references(processor)
      Logger.debug("refs for #{id}:  #{inspect references}")
      Enum.each(references, fn ref ->
        :digraph.add_edge(g, id, ref)
      end)
    end)

    :digraph_utils.postorder(g)
  end

  defp get_references(%{operandA: %{"@ref": id}}), do: [id]
  defp get_references(%{operandA: %{"@ref": idA}, operandB: %{"@ref": idB}}), do: [idA, idB]
  defp get_references(%{predecessor: %{"@ref": id}}), do: [id]
  defp get_references(%{input: %{"@ref": id}}), do: [id]
  defp get_references(%{inputEvents: %{"@ref": idA}, conditionSignal: %{"@ref": idB}}) do
    [idA, idB]
  end
  defp get_references(%{control: %{"@ref": idA}, trueNode: %{"@ref": idB}}), do: [idA, idB]
  defp get_references(_), do: []
end
