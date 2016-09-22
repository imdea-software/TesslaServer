defmodule TesslaServer.Computation.Aggregation.SignalMaximumTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Aggregation.SignalMaximum
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  doctest SignalMaximum

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    SignalMaximum.start @processor, [@op1]
    :ok
  end

  test "Should take value of new event if it is bigger than previous maximum" do
    GenComputation.add_child(@processor, @test)

    timestamp0 = Duration.zero
    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    event0 = %Event{timestamp: timestamp0, value: 0, stream_id: @op1, type: :change}
    event1 = %Event{timestamp: timestamp1, value: 4, stream_id: @op1, type: :change}
    event2 = %Event{
      timestamp: timestamp2, value: 6, stream_id: @op1, type: :change
    }
    event3 = %Event{
      timestamp: timestamp3, value: 6, stream_id: @op1, type: :change
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op1, type: :progress
    }


    GenComputation.send_event(@processor, event0)
    assert_receive({_, {:process, change0}})
    assert change0.timestamp == Duration.zero
    assert change0.value == event0.value
    assert change0.type == :change


    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:process, change1}})
    assert change1.timestamp == timestamp1
    assert change1.value == event1.value
    assert change1.type == :change

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
