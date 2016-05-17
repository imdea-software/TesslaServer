defmodule TesslaServer.Node.SpecProcessor.MinimalTest do
  use ExUnit.Case, async: false

  alias TesslaServer.{Node, SpecProcessor}

  test "should setup a node for each minimal example" do
    {:ok, spec} = File.read("test/examples/minimal.tessla")
    ids = SpecProcessor.process spec

    assert Enum.count(ids) == 68

    Enum.each ids, &Node.stop(&1)
  end
end
