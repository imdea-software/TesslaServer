defmodule TesslaServer.Computation.Timing.InPastTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.InPast
  alias TesslaServer.{Event, GenComputation, Registry, Source}

  import System, only: [unique_integer: 0]

  doctest InPast

  @op1 unique_integer
  @amount 100000
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    InPast.start @processor, [@op1], %{amount: @amount}
    :ok
  end

  test "should emit if an event happened in specified time in past" do
    GenComputation.add_child(@processor, @test)

    Source.start_evaluation

    assert_receive({_, {:process, change0}})

    refute change0.value
    assert change0.timestamp == Duration.zero
    assert change0.type == :change

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_microseconds(100000))
    timestamp3 = Duration.add(timestamp2, Duration.from_microseconds(100001))
    event1 = %Event{timestamp: timestamp1, stream_id: @op1}
    event2 = %Event{
      timestamp: timestamp2, stream_id: @op1
    }
    event3 = %Event{
      timestamp: timestamp3, stream_id: @op1
    }

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:process, change1}})
    assert change1.timestamp == timestamp1
    assert change1.value
    assert change1.type == :change

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:process, change2}})
    assert change2.timestamp == timestamp2
    assert change2.value == :nothing
    assert change2.type == :progress

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:process, change3}})
    assert_receive({_, {:process, change4}})
    assert change3.timestamp == Duration.add(timestamp2, Duration.from_microseconds(@amount))
    refute change3.value
    assert change3.type == :change

    assert change4.timestamp == timestamp3
    assert change4.value
    assert change4.type == :change

    :ok = GenComputation.stop(@processor)
  end
end
