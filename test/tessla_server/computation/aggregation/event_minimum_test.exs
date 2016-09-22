defmodule TesslaServer.Computation.Aggregation.EventMinimumTest do
  use ExUnit.Case, async: false
  use Timex

  alias TesslaServer.Computation.Aggregation.EventMinimum
  alias TesslaServer.{Event, GenComputation, Registry, Source}

  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @default_value 5
  @test unique_integer
  @processor unique_integer

  doctest EventMinimum

  setup do
    Registry.register @test
    EventMinimum.start @processor, [@op1], %{default: @default_value}
    :ok
  end

  test "Should take value of new event if it is smaller than previous minimum" do
    GenComputation.add_child(@processor, @test)

    Source.start_evaluation
    assert_receive({_, {:process, change0}})
    assert change0.timestamp == Duration.zero
    assert change0.value == @default_value
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
    assert change1.type == :progress

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
