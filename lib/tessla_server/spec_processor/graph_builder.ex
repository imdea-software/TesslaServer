defmodule TesslaServer.SpecProcessor.GraphBuilder do
  @moduledoc """
  Takes a Tessla spec and generates a DAG of `TesslaServer.Node` modules which represents the spec
  """

  require Logger

  alias TesslaServer.Node
  alias TesslaServer.Source

  @spec build(%{}) :: :ok
  def build(spec = %{}) do
    list = get_ordered_list spec

    Logger.debug inspect list
    Enum.each(list, fn key -> build_stream {key, spec[key]} end)
    :ok
  end

  defp build_stream(all = {name, definition}) do
    build_node(definition, name)
  end

  defp build_node(definition), do: build_node(definition, unique_name)

  defp build_node(%{def: %{function: :leq, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)
    Logger.debug("leq: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Leq.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :add, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("add: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Add.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :sub, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("sub: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Sub.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :mul, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("mul: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Mul.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :div, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("div: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Div.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :geq, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("geq: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Geq.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :eq, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("eq: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Eq.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :max, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("max: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Max.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :min, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("min: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Min.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :abs, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("abs: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Abs.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :and, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("and: #{name}, args: #{inspect ancestors}")

    Node.Lifted.And.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :or, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("or: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Or.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :implies, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("implies: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Implies.start name, ancestors

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :not, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    Logger.debug("not: #{name}, args: #{inspect ancestors}")

    Node.Lifted.Not.start name, ancestors

    add_to_ancestors(name, ancestors)
  end


  defp build_node(%{def: %{function: :function_call_parameter, args: args}}, name) do
    [%{def: %{literal: function_name}}| [%{def: %{literal: param_pos}} | []]] = args

    Logger.debug("function_call_parameter: #{name}, function name: #{inspect function_name},
    param_pos: #{param_pos}")
    options = %{param_pos: param_pos}
    input_name = "function_call:#{function_name}" |> String.to_atom
    Source.FunctionCallParameter.start name, [input_name], options
  end

  defp build_node(%{def: %{function: :variable_update, args: args}}, name) do
    [%{def: %{literal: variable_name}}] = args

    Logger.debug("variable_update: #{name}, variable name: #{inspect variable_name}")

    input_name = "variable_update:#{variable_name}" |> String.to_atom
    Source.VariableUpdate.start name, [input_name]
  end

  defp build_node(%{def: %{literal: value}}, name) do
    Logger.debug("Literal #{name}, value: #{inspect value}")
    Node.Literal.start(name: name, value: value)
    name
  end

  defp build_node(%{def: %{stream: stream_name}}, name), do: stream_name

  defp add_to_ancestors(child, ancestors) do
    Enum.each(ancestors, &(Node.add_child(&1, child)))
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
      # Logger.debug("refs for #{inspect key}:  #{inspect references}")
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
    definitions
    |> Enum.map(fn definition ->
      get_references definition
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq
    |> List.flatten
  end
  defp get_references(%{def: %{}}), do: []

end
