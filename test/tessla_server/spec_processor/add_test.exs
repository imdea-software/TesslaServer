defmodule TesslaServer.Node.SpecProcessor.AddTest do
  use ExUnit.Case, async: true

  alias TesslaServer.{Node, SpecProcessor}

  test "Should Parse and Setup an adder" do
    {:ok, spec} = File.read("test/examples/math/add.tessla")
    SpecProcessor.process spec
    :timer.sleep 1000
    output_event = Node.get_latest_output :added
    IO.puts inspect output_event
    assert(output_event.value == 8)
  end
end
