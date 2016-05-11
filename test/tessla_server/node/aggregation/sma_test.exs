defmodule TesslaServer.Node.Aggregation.SmaTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Aggregation.Sma
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest Sma

  @op1 unique_integer
  @count 3
  @test unique_integer
  @processor unique_integer

  setup do
    :gproc.reg(gproc_tuple(@test))
    Sma.start @processor, [@op1], %{count: @count}
    :ok
  end

  test "should emit sma on every new event" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: []}}})

    timestamp = DateTime.now
    event1 = %Event{value: 1, timestamp: to_timestamp(timestamp), stream_id: @op1}
    event2 = %Event{
      value: 2, timestamp: to_timestamp(shift(timestamp, seconds: 2)), stream_id: @op1
    }
    event3 = %Event{
      value: 3, timestamp: to_timestamp(shift(timestamp, seconds: 3)), stream_id: @op1
    }
    event4 = %Event{
      value: 4, timestamp: to_timestamp(shift(timestamp, seconds: 4)), stream_id: @op1
    }
    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: [out0]}}})
    assert out0.timestamp == event1.timestamp
    assert out0.value == (event1.value / 1)

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: [out1, ^out0]}}})
    assert out1.timestamp == event2.timestamp
    assert out1.value == ((event1.value + event2.value) / 2)

    Node.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{events: [out2, ^out1, ^out0]}}})
    assert out2.timestamp == event3.timestamp
    assert out2.value == ((event1.value + event2.value + event3.value) / 3)

    Node.send_event(@processor, event4)

    assert_receive({_, {:update_input_stream, %{events: [out3, ^out2, ^out1, ^out0]}}})
    assert out3.timestamp == event4.timestamp
    assert out3.value == ((event2.value + event3.value + event4.value) / 3)

    :ok = Node.stop(@processor)
  end
end
