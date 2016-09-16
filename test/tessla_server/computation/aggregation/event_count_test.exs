defmodule TesslaServer.Node.Aggregation.EventCountTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Aggregation.EventCount
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest EventCount

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    :gproc.reg(gproc_tuple(@test))
    EventCount.start @processor, [@op1]
    :ok
  end

  test "Should increment eventcount on every new event" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{type: :signal, events: [out0]}}})
    assert(out0.value == 0)

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), stream_id: @op1}
    event2 = %Event{
      timestamp: to_timestamp(shift(timestamp, seconds: 2)), stream_id: @op1
    }

    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: [out1, ^out0]}}})
    assert out1.timestamp == event1.timestamp
    assert out1.value == 1

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: [out2, ^out1, ^out0]}}})
    assert out2.value == 2
    assert out2.timestamp == event2.timestamp

    :ok = Node.stop(@processor)
  end
end
