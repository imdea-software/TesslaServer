defmodule TesslaServer.Computation.Aggregation.EventCountTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Aggregation.EventCount
  alias TesslaServer.{Event, GenComputation, Registry, Source}

  import System, only: [unique_integer: 0]

  doctest EventCount

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    EventCount.start @processor, [@op1]
    :ok
  end

  test "Should increment eventcount on every new event" do
    GenComputation.add_child(@processor, @test)

    Source.start_evaluation

    assert_receive({_, {:process, change0}})
    assert(change0.value == 0)

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(3))

    event1 = %Event{timestamp: timestamp1, stream_id: @op1}
    progress2 = %Event{
      timestamp: timestamp2, stream_id: @op1, type: :progress
    }
    event3 = %Event{
      timestamp: timestamp3, stream_id: @op1
    }

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:process, change1}})
    assert change1.timestamp == timestamp1
    assert change1.value == 1
    assert change1.type == :change

    GenComputation.send_event(@processor, progress2)

    assert_receive({_, {:process, change2}})
    assert change2.type == :progress
    assert change2.timestamp == timestamp2

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:process, change3}})
    assert change3.timestamp == timestamp3
    assert change3.value == 2
    assert change3.type == :change

    :ok = GenComputation.stop(@processor)
  end
end
