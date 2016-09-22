defmodule TesslaServer.Computation.Aggregation.SumTest do
  use ExUnit.Case, async: false
  use Timex

  alias TesslaServer.Computation.Aggregation.Sum
  alias TesslaServer.{Event, GenComputation, Registry, Source}

  import System, only: [unique_integer: 0]

  doctest Sum

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    Sum.start @processor, [@op1]
    :ok
  end

  test "Should sum value of all events happened" do
    GenComputation.add_child(@processor, @test)

    Source.start_evaluation

    assert_receive({_, {:process, change0}})
    assert change0.value == 0
    assert change0.type == :change
    assert change0.timestamp == Duration.zero

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    event1 = %Event{timestamp: timestamp1, stream_id: @op1, value: 1}
    event2 = %Event{
      timestamp: timestamp2, stream_id: @op1, value: 3
    }
    event3 = %Event{
      timestamp: timestamp3, stream_id: @op1, type: :progress
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op1, value: 4
    }

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:process, change1}})
    assert change1.value == 1
    assert change1.type == :change
    assert change1.timestamp == timestamp1

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:process, change2}})
    assert change2.value == 4
    assert change2.type == :change
    assert change2.timestamp == timestamp2

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:process, change3}})
    assert change3.type == :progress
    assert change3.timestamp == timestamp3

    GenComputation.send_event(@processor, event4)

    assert_receive({_, {:process, change4}})
    assert change4.value == 8
    assert change4.type == :change
    assert change4.timestamp == timestamp4

    :ok = GenComputation.stop(@processor)
  end
end
