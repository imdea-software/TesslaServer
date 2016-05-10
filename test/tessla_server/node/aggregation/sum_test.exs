defmodule TesslaServer.Node.Aggregation.SumTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Aggregation.Sum
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest Sum

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    :gproc.reg(gproc_tuple(@test))
    Sum.start @processor, [@op1]
    :ok
  end

  test "Should sum value of all events happened" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: [out0]}}})
    assert(out0.value == 0)

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), stream_id: @op1, value: 1}
    event2 = %Event{
      timestamp: to_timestamp(shift(timestamp, seconds: 2)), stream_id: @op1, value: 3
    }
    event3 = %Event{
      timestamp: to_timestamp(shift(timestamp, seconds: 4)), stream_id: @op1, value: 4
    }

    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: [out1, ^out0]}}})
    assert out1.timestamp == event1.timestamp
    assert out1.value == 1

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: [out2, ^out1, ^out0]}}})
    assert out2.value == 4
    assert out2.timestamp == event2.timestamp

    Node.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{events: [out3, ^out2, ^out1, ^out0]}}})
    assert out3.value == 8
    assert out3.timestamp == event3.timestamp

    :ok = Node.stop(@processor)
  end
end