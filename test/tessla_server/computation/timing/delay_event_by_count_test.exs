defmodule TesslaServer.Computation.Timing.DelayEventByCountTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.DelayEventByCount
  alias TesslaServer.{Event, GenComputation, Registry}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest DelayEventByCount

  @op1 unique_integer
  @count 2
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    DelayEventByCount.start @processor, [@op1], %{count: @count}
    :ok
  end

  test "Should delay events by specified count" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{type: :events, events: []}}})

    event1 = %Event{timestamp: {0, 1, 0}, stream_id: @op1, value: 1}
    event2 = %Event{
      timestamp: {0, 1, 5}, stream_id: @op1, value: 2
    }
    event3 = %Event{
      timestamp: {0, 5, 0}, stream_id: @op1, value: 3
    }
    event4 = %Event{
      timestamp: {0, 6, 0}, stream_id: @op1, value: 4
    }

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert progressed_to == event1.timestamp

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert progressed_to == event2.timestamp

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out1]}}})
    assert progressed_to == event3.timestamp
    assert out1.timestamp == event3.timestamp
    assert out1.value == 1

    GenComputation.send_event(@processor, event4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out2, ^out1]}}})
    assert progressed_to == event4.timestamp
    assert out2.timestamp == event4.timestamp
    assert out2.value == 2

    :ok = GenComputation.stop(@processor)
  end
end
