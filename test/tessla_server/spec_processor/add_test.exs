defmodule TesslaServer.Node.SpecProcessor.AddTest do
  use ExUnit.Case, async: false

  alias TesslaServer.{GenComputation, SpecProcessor}

  @adder 1

  setup do
    {:ok, spec} = File.read("test/examples/math/add.tessla")
    ids = SpecProcessor.process spec
    on_exit fn ->
      Enum.each ids, fn id ->
        :ok = GenComputation.stop id
      end
    end
  end

  test "Should Parse and Setup an adder" do
    :timer.sleep 1000
    latest_output  = GenComputation.get_latest_output @adder

    assert(latest_output.value == 8)
    assert latest_output.timestamp == {0, 0, 1}
  end
end
