defmodule TesslaServer.Node.SpecProcessor.AddTest do
  use ExUnit.Case, async: true

  alias TesslaServer.{Node, SpecProcessor}

  @adder 1

  test "Should Parse and Setup an adder" do
    {:ok, spec} = File.read("test/examples/math/add.tessla")
    SpecProcessor.process spec
    :timer.sleep 1000
    history = Node.get_history @adder

    latest_output = hd(history.output.events)
    assert(latest_output.value == 8)
    assert history.output.progressed_to == {0, 0, 1}
  end
end
