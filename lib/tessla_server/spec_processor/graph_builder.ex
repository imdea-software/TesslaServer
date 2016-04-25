defmodule TesslaServer.SpecProcessor.GraphBuilder do
  @moduledoc """
  Takes a Tessla spec and generates a DAG of `TesslaServer.Node` modules which represents the spec
  """

  alias TesslaServer.Node
  alias TesslaServer.Source

  @spec build(%{}) :: :ok
  def build(spec = %{}) do
    list = get_ordered_list spec

    IO.puts inspect list
    Enum.each(list, fn key -> build_stream {key, spec[key]} end)
    :ok
  end

  defp build_stream(all = {name, definition}) do
    build_node(definition, name)
  end

  defp build_node(definition), do: build_node(definition, unique_name)

  defp build_node(%{def: %{function: :leq, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)
    IO.puts("leq: #{name}, args: #{inspect ancestors}")

    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Leq.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :add, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("add: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Add.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :sub, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("sub: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Sub.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :mul, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("mul: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Mul.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :div, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("div: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Div.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :geq, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("geq: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Geq.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :eq, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("eq: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Eq.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :max, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("max: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Max.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :min, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("min: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Min.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :abs, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("abs: #{name}, args: #{inspect ancestors}")
    [stream1 | _] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1}}

    Node.Lifted.Abs.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :and, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("and: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.And.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :or, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("or: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Or.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :implies, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("implies: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Implies.start options

    add_to_ancestors(name, ancestors)
  end

  defp build_node(%{def: %{function: :not, args: args}}, name) do
    ancestors = Enum.map(args, &build_node/1)

    IO.puts("not: #{name}, args: #{inspect ancestors}")
    [stream1 | [stream2 | _]] = ancestors

    options = %{stream_name: name, options: %{operand1: stream1, operand2: stream2}}

    Node.Lifted.Not.start options

    add_to_ancestors(name, ancestors)
  end


  defp build_node(%{def: %{function: :function_call_parameter, args: args}}, name) do
    [%{def: %{literal: function_name}}| [%{def: %{literal: param_pos}} | []]] = args

    IO.puts("function_call_parameter: #{name}, function name: #{inspect function_name}, param_pos: #{param_pos}")
    options = %{stream_name: name, options: %{function_name: function_name, param_pos: param_pos}}
    Source.FunctionCallParameter.start options
  end

  defp build_node(%{def: %{function: :variable_update, args: args}}, name) do
    [%{def: %{literal: variable_name}}] = args

    IO.puts("variable_update: #{name}, variable name: #{inspect variable_name}")
    options = %{stream_name: name, options: %{variable_name: variable_name}}
    Source.VariableUpdate.start options
  end

  defp build_node(%{def: %{literal: value}}, name) do
    IO.puts("Literal #{name}, value: #{inspect value}")
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
      # IO.puts("refs for #{inspect key}:  #{inspect references}")
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
