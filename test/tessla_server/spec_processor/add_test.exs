defmodule TesslaServer.Computation.SpecProcessor.AddTest do
  use ExUnit.Case, async: false

  require Logger

  alias TesslaServer.{GenComputation, SpecProcessor, Output, Registry}
  alias TesslaServer.Computation.Literal
  import System, only: [unique_integer: 0]
  import TesslaServer.Registry, only: [gproc_tuple: 1]


  @adder 1
  @test unique_integer

  setup do
    :gproc.reg(Registry.gproc_tuple(@test))
    Output.stop
    Output.start %{@adder => "adder"}
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

    Literal.start_literals

    assert_receive {_, {:process, event}}
    assert event.timestamp == :literal
  end
end
