defmodule TesslaServer.SpecProcessor.SimpleCounterTest do
  use ExUnit.Case, async: false

  alias TesslaServer.{GenComputation, Source, SpecProcessor, Event, Registry}
  import System, only: [unique_integer: 0]

  use Timex

  @over_one_second 1
  @call_id unique_integer
  @return_id unique_integer
  @test unique_integer

  setup do
    Registry.register @test
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

    Source.start_evaluation

    timestamp1 = Duration.from_milliseconds 1
    timestamp2 = Duration.from_microseconds 1100

    timestamp3 = Duration.from_milliseconds 3
    timestamp4 = Duration.from_microseconds 4100

    timestamp5 = Duration.from_milliseconds 6

    call1 = %Event{timestamp: timestamp1, stream_id: @call_id}
    return1 = %Event{timestamp: timestamp2, stream_id: @return_id}

    call2 = %Event{timestamp: timestamp3, stream_id: @call_id}
    return2 = %Event{timestamp: timestamp4, stream_id: @return_id}

    call3 = %Event{timestamp: timestamp5, stream_id: @call_id}

    Source.distribute(call_channel, call1)
    Source.distribute(return_channel, return1)
    assert_receive {_, {:process, progress0}}
    assert progress0.timestamp == Duration.zero
    assert progress0.type == :progress

    assert_receive {_, {:process, progress1}}
    assert progress1.timestamp == timestamp1
    assert progress1.type == :progress

    Source.distribute(call_channel, call2)

    assert_receive {_, {:process, event1}}
    assert event1.value
    assert event1.type == :event
    assert event1.timestamp == timestamp2

    Source.distribute(return_channel, return2)

    assert_receive {_, {:process, progress2}}
    assert progress2.timestamp == Duration.add(timestamp1, Duration.from_milliseconds(1))
    assert progress2.type == :progress

    assert_receive {_, {:process, progress3}}
    assert progress3.timestamp == timestamp3
    assert progress3.type == :progress

    Source.distribute(call_channel, call3)

    assert_receive {_, {:process, progress4}}
    assert progress4.type == :progress
    assert progress4.timestamp == Duration.add(timestamp3, Duration.from_milliseconds(1))

    assert_receive {_, {:process, event2}}
    refute event2.value
    assert event2.type == :event
    assert event2.timestamp == timestamp4
    refute_receive _
  end
end
