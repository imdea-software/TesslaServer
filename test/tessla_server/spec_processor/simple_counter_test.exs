defmodule TesslaServer.Node.SpecProcessor.SimpleCounterTest do
  use ExUnit.Case, async: false

  alias TesslaServer.{GenComputation, Source, SpecProcessor, Event, Registry, Output}
  import System, only: [unique_integer: 0]
  require Logger

  @over_one_second 1
  @call_id unique_integer
  @return_id unique_integer
  @test unique_integer

  setup do
    Output.stop
    Output.start %{@over_one_second => "i-t-e"}
    :gproc.reg(Registry.gproc_tuple(@test))
    {:ok, spec} = File.read("test/examples/simple_counter/simple_counter.tessla")
    ids = SpecProcessor.process spec

    on_exit fn ->
      Enum.each ids, fn id ->
        :ok = GenComputation.stop id
      end
    end
  end

  test "Should detect if function took longer than a millisecond" do
    call_channel = "function_calls:counter.c:inc"
    return_channel = "function_returns:counter.c:inc"

    GenComputation.add_child(@over_one_second, @test)

    call1 = %Event{timestamp: {0, 1, 0}, stream_id: @call_id}
    return1 = %Event{timestamp: {0, 1, 100}, stream_id: @return_id}
    call2 = %Event{timestamp: {0, 1, 100}, stream_id: @call_id}

    Source.distribute(call_channel, call1)
    Source.distribute(call_channel, call2)
    Source.distribute(return_channel, return1)

    assert_receive {_, {:process, event}}
  end
end
