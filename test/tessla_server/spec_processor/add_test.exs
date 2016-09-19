defmodule TesslaServer.Computation.SpecProcessor.AddTest do
  use ExUnit.Case, async: false

  require Logger

  alias TesslaServer.{GenComputation, SpecProcessor, Output}

  import ExUnit.CaptureLog

  @adder 1

  test "Should Parse and Setup an adder" do
    Output.stop
    Output.start %{@adder => "adder"}
    {:ok, spec} = File.read("test/examples/math/add.tessla")
    logged = capture_log fn ->
      ids = SpecProcessor.process spec
      :timer.sleep(1000)

      on_exit fn ->
        Enum.each ids, fn id ->
          :ok = GenComputation.stop id
        end
      end
    end
    assert String.contains? logged, "time: :literal, value: :nothing"
  end
end
