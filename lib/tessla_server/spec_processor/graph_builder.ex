defmodule TesslaServer.SpecProcessor.GraphBuilder do
  @moduledoc """
  Takes a Tessla spec and generates a DAG of `TesslaServer.Node` modules which represents the spec
  """

  require Logger

  alias TesslaServer.Node
  alias TesslaServer.Source

  @nodes %{
    "dataFlowGraph.node.operation.AddNode" => Node.Lifted.Add,
    "dataFlowGraph.node.operation.SubNode" => Node.Lifted.Sub,
    "dataFlowGraph.node.operation.ConstantNode" => Node.Literal,
    "dataFlowGraph.node.input.InstructionExecutionsNode" => Source.InstructionExecutions,
    "dataFlowGraph.node.input.FunctionCallsNode" => Source.FunctionCalls,
    "dataFlowGraph.node.input.VariableValueNode" => Source.VariableUpdate,
    "dataFlowGraph.node.input.FunctionReturnsNode" => Source.FunctionReturns,
    "dataFlowGraph.node.operation.TimestampNode" => Node.Timing.Timestamp,
    "dataFlowGraph.node.operation.EventCountNode" => Node.Aggregation.EventCount,
    "dataFlowGraph.node.operation.MostRecentValueNode" => Node.Aggregation.Mrv,
    "dataFlowGraph.node.operation.NotNode" => Node.Lifted.Not,
    "dataFlowGraph.node.operation.AndNode" => Node.Lifted.And,
    "dataFlowGraph.node.operation.OrNode" => Node.Lifted.Or,
    "dataFlowGraph.node.operation.NegNode" => Node.Lifted.Neg,
    "dataFlowGraph.node.operation.GTNode" => Node.Lifted.Gt,
    "dataFlowGraph.node.operation.EQNode" => Node.Lifted.Eq,
    "dataFlowGraph.node.operation.OccursAllNode" => Node.Filter.OccursAll,
    "dataFlowGraph.node.operation.OccursAnyNode" => Node.Filter.OccursAny,
    "dataFlowGraph.node.operation.MergeNode" => Node.Filter.Merge,
    "dataFlowGraph.node.operation.InPastNode" => Node.Timing.InPast,
    "dataFlowGraph.node.operation.IfThenNode" => Node.Filter.IfThen,
    "dataFlowGraph.node.operation.DelayNode" => Node.Timing.Delay,
    "dataFlowGraph.node.operation.FilterNode" => Node.Filter.Filter,
    "dataFlowGraph.node.operation.ChangeOfNode" => Node.Filter.ChangeOf,
  }

  @spec build([%{atom => any}]) :: :ok
  def build(spec) when is_list(spec) do
    ids = Enum.map spec, &(&1[:"@id"])

    Enum.each spec, fn processor ->
      unless processor[:"@type"] in Map.keys(@nodes), do: raise "unknown node"
      build_node processor
    end

    Enum.each ids, &Node.subscribe_to_parents(&1)
    :ok
  end

  defp build_node(json = %{"@type": type}) do
    id = json[:"@id"]
    Logger.debug("#{inspect type}, id: %{inspect id}")

    ancestors = get_references json
    options = get_options json

    @nodes[type].start id, ancestors, options
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

  defp get_references(%{operandA: %{"@ref": id}}), do: [id]
  defp get_references(%{operandA: %{"@ref": idA}, operandB: %{"@ref": idB}}), do: [idA, idB]
  defp get_references(%{predecessor: %{"@ref": id}}), do: [id]
  defp get_references(%{input: %{"@ref": id}}), do: [id]
  defp get_references(%{inputEvents: %{"@ref": idA}, conditionSignal: %{"@ref": idB}}) do
    [idA, idB]
  end
  defp get_references(%{control: %{"@ref": idA}, trueNode: %{"@ref": idB}}), do: [idA, idB]
  defp get_references(_), do: []

  defp get_options(%{initialValue: value}), do: %{default: value}
  defp get_options(%{argument: value}), do: %{argument: value}
end
