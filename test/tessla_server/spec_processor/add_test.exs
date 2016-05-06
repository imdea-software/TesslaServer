defmodule TesslaServer.Node.SpecProcessor.AddTest do
  use ExUnit.Case, async: true

  alias TesslaServer.{Node, SpecProcessor}

  # test "Should Parse and Setup an adder" do
  #   {:ok, spec} = File.read("test/examples/math/add.tessla")
  #   SpecProcessor.process spec
  #   :timer.sleep 1000
  #   history = Node.get_history :added

  #   latest_output = hd(history.output.events)
  #   assert(latest_output.value == 8)
  # end
end
