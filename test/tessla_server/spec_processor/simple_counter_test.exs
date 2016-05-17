defmodule TesslaServer.Node.SpecProcessor.SimpleCounterTest do
  use ExUnit.Case, async: false

  alias TesslaServer.{Node, Source, SpecProcessor, Event}
  import System, only: [unique_integer: 0]
  import TesslaServer.Registry

  @overOneSecond 1
  @call_id unique_integer
  @return_id unique_integer
  @test unique_integer

  setup do
    :gproc.reg(gproc_tuple(@test))
    {:ok, spec} = File.read("test/examples/simple_counter.tessla")
    ids = SpecProcessor.process spec
    on_exit fn ->
      Enum.each ids, fn id ->
        :ok = Node.stop id
      end
    end
  end

  test "Should detect if function took longer than a millisecond" do
    call_channel = "function_calls:counter.c:inc"
    return_channel = "function_returns:counter.c:inc"

    Node.add_child(@overOneSecond, @test)
    assert_receive {_, {:update_input_stream, %{type: :events, events: []}}}

    call1 = %Event{timestamp: {0, 1, 0}, stream_id: @call_id}
    return1 = %Event{timestamp: {0, 1, 100}, stream_id: @return_id}

    Source.distribute(call_channel, call1)
    Source.distribute(return_channel, return1)

  end
end
