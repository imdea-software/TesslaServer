defmodule TesslaServer.Computation.Aggregation.MrvTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Aggregation.Mrv
  alias TesslaServer.{Event, Source, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  doctest Mrv

  @op1 unique_integer
  @default 1
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    Mrv.start @processor, [@op1], %{default: @default}
    :ok
  end

  test "Should change value of signal on every event with new value" do
    GenComputation.add_child(@processor, @test)

    Source.start_evaluation
    assert_receive({_, {:process, change0}})
    assert change0.timestamp == Duration.zero
    assert change0.value == @default
    assert change0.type == :change

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    event1 = %Event{timestamp: timestamp1, value: 6, stream_id: @op1}
    event2 = %Event{
      timestamp: timestamp2, value: 4, stream_id: @op1
    }
    event3 = %Event{
      timestamp: timestamp3, value: 4, stream_id: @op1
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op1, type: :progress
    }


    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:process, change1}})
    assert change1.timestamp == timestamp1
    assert change1.type == :change
    assert change1.value == 6

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:process, change2}})
    assert change2.timestamp == timestamp2
    assert change2.value == event2.value
    assert change2.type == :change

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:process, change3}})
    assert change3.timestamp == timestamp3
    assert change3.type == :progress

    GenComputation.send_event(@processor, event4)

    assert_receive({_, {:process, change4}})
    assert change4.timestamp == timestamp4
    assert change3.type == :progress


    :ok = GenComputation.stop(@processor)
  end
end
