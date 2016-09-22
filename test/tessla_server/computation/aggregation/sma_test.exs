defmodule TesslaServer.Computation.Aggregation.SmaTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Aggregation.Sma
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  doctest Sma

  @op1 unique_integer
  @count 3
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    Sma.start @processor, [@op1], %{count: @count}
    :ok
  end

  test "should emit sma on every new event" do
    GenComputation.add_child(@processor, @test)

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))
    timestamp5 = Duration.add(timestamp1, Duration.from_seconds(4))

    event1 = %Event{value: 1, timestamp: timestamp1, stream_id: @op1}
    event2 = %Event{
      value: 2, timestamp: timestamp2, stream_id: @op1
    }
    event3 = %Event{
      value: 3, timestamp: timestamp3, stream_id: @op1
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op1, type: :progress
    }
    event5 = %Event{
      value: 4, timestamp: timestamp5, stream_id: @op1
    }

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:process, sma1}})
    assert sma1.timestamp == event1.timestamp
    assert sma1.value == (event1.value / 1)
    assert sma1.type == :event

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:process, sma2}})
    assert sma2.timestamp == event2.timestamp
    assert sma2.value == ((event1.value + event2.value) / 2)
    assert sma2.type == :event

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:process, sma3}})
    assert sma3.timestamp == event3.timestamp
    assert sma3.value == ((event1.value + event2.value + event3.value) / 3)
    assert sma3.type == :event

    GenComputation.send_event(@processor, event4)

    assert_receive({_, {:process, sma4}})
    assert sma4.timestamp == event4.timestamp
    assert sma4.type == :progress

    GenComputation.send_event(@processor, event5)

    assert_receive({_, {:process, sma5}})
    assert sma5.timestamp == event5.timestamp
    assert sma5.value == ((event2.value + event3.value + event5.value) / 3)
    assert sma5.type == :event

    :ok = GenComputation.stop(@processor)
  end
end
