defmodule TesslaServer.Computation.SpecProcessor.MinimalTest do
  use ExUnit.Case, async: false

  alias TesslaServer.{GenComputation, SpecProcessor}

  test "should setup a node for each minimal example" do
    {:ok, spec} = File.read("test/examples/minimal/minimal.tessla")
    ids = SpecProcessor.process spec

    assert Enum.count(ids) == 68

    Enum.each ids, &GenComputation.stop(&1)
  end
end
