defmodule TesslaServer.Computation.Timing.TimestampsTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.Timestamps
  alias TesslaServer.{Event, GenComputation, Registry}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest Timestamps

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    Timestamps.start @processor, [@op1]
    :ok
  end

  test "should emit timestamp of every received event" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{type: :events, events: []}}})

    timestamp1 = DateTime.now
    timestamp2 = shift(timestamp1, seconds: 2)
    timestamp3 = shift(timestamp1, seconds: 3)
    event1 = %Event{timestamp: to_timestamp(timestamp1), stream_id: @op1}
    event2 = %Event{
      timestamp: to_timestamp(timestamp2), stream_id: @op1
    }
    event3 = %Event{
      timestamp: to_timestamp(timestamp3), stream_id: @op1
    }

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: [out0]}}})
    assert out0.timestamp == event1.timestamp
    assert out0.value == event1.timestamp

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: [out1, ^out0]}}})
    assert out1.value == event2.timestamp
    assert out1.timestamp == event2.timestamp

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{events: [out2, ^out1, ^out0]}}})
    assert out2.value == event3.timestamp
    assert out2.timestamp == event3.timestamp

    :ok = GenComputation.stop(@processor)
  end
end
