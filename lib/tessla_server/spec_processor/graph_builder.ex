defmodule TesslaServer.SpecProcessor.GraphBuilder do
  @moduledoc """
  Takes a Tessla spec and generates a DAG of `TesslaServer.Node` modules which represents the spec
  """

  alias TesslaServer.Literal
  alias TesslaServer.Node
  alias TesslaServer.Node.{Leq,Add,Multiply}
  alias TesslaServer.Source.{FunctionCallParameter}

  import TesslaServer.Registry

  @spec build(%{}) :: %{atom: pid}
  def build(spec = %{}) do
    list = get_ordered_list spec

    Enum.map(list, fn key -> build_stream {key, spec[key]} end)
    #GenServer.cast(via_tuple(name), {:add_child, :a})
  end

  defp build_stream(all = {name, definition}) do

    build_node(definition, name)

    #GenServer.start(name: via_tuple(name))
  end

  defp build_node(definition), do: build_node(definition, unique_name)

  defp build_node(%{def: %{function: :leq, args: args}}, name) do
    IO.puts("leq: #{name}, args: #{inspect args}")
    ancestors = Enum.map(args, &build_node/1)

    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Leq.start options


    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :function_call_parameter, args: args}}, name) do
    [%{def: %{literal: function_name}}| [%{def: %{literal: param_pos}} | []]] = args

    IO.puts("function_call_parameter: #{name}, function name: #{inspect function_name}, param_pos: #{param_pos}")
    options = %{stream_name: name, options: %{function_name: function_name, param_pos: param_pos}}
    FunctionCallParameter.start options
  end

  defp build_node(%{def: %{literal: value}}, name) do
    IO.puts("Literal #{name}, value: #{inspect value}")
    Literal.start(name: name, value: value)
    name
  end

  defp build_node(%{def: %{stream: stream_name}}, name), do: stream_name

  defp add_to_ancestors(child, ancestors) do
    Enum.map(ancestors, &(GenServer.cast(via_tuple(&1), {:add_child, child})))
    child
  end

  defp unique_name do
    System.unique_integer |> Integer.to_string
  end

  defp get_ordered_list(spec) do
    keys = Map.keys(spec)

    g = :digraph.new([:acyclic])
    Enum.each(keys, fn key ->
      :digraph.add_vertex(g, key)
    end)

    Enum.each(spec, fn {key, value} ->
      references = get_references(value)
      #IO.puts("refs for #{inspect key}:  #{inspect references}")
      Enum.each(references, fn ref ->
        :digraph.add_edge(g, key, ref)
      end)
    end)

    :digraph_utils.postorder(g)
  end

  defp get_references(%{def: %{stream: name}}) do
    name
  end
  defp get_references(%{def: %{args: definitions}}) do
    Enum.map(definitions, fn definition ->
      get_references definition
    end) |> Enum.reject(&is_nil/1) |> Enum.uniq |> List.flatten
  end
  defp get_references(%{def: %{}}), do: nil

end
