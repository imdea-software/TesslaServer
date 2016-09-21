defmodule TesslaServer.SpecProcessor.AddTest do
  use ExUnit.Case, async: false

  require Logger

  alias TesslaServer.{GenComputation, SpecProcessor, Registry, Source}
  import System, only: [unique_integer: 0]


  @adder 1
  @test unique_integer

  setup do
    Registry.register @test
    {:ok, spec} = File.read("test/examples/math/add.tessla")
    ids = SpecProcessor.process spec
    on_exit fn ->
      Enum.each ids, fn id ->
        :ok = GenComputation.stop id
      end
    end
  end

  test "Should Parse and Setup an adder" do
    GenComputation.add_child @adder, @test

    Source.start_evaluation

    assert_receive {_, {:process, event}}
    assert event.type == :change
    assert event.timestamp == :literal
    assert event.value == 8
  end
end
