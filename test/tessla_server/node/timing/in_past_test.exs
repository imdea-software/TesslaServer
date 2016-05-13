defmodule TesslaServer.Node.Timing.InPastTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Timing.InPast
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest InPast

  @op1 unique_integer
  @amount 50000
  @test unique_integer
  @processor unique_integer

  setup do
    :gproc.reg(gproc_tuple(@test))
    InPast.start @processor, [@op1], %{amount: @amount}
    :ok
  end

  test "should emit if an event happened in specified time in past" do
    Node.add_child(@processor, @test)

    assert_receive({_, {:update_input_stream, %{type: :signal, events: [out0]}}})
    refute out0.value

    timestamp1 = DateTime.now
    timestamp2 = shift(timestamp1, milliseconds: 20)
    timestamp3 = shift(timestamp1, seconds: 3)
    event1 = %Event{timestamp: to_timestamp(timestamp1), stream_id: @op1}
    event2 = %Event{
      timestamp: to_timestamp(timestamp2), stream_id: @op1
    }
    event3 = %Event{
      timestamp: to_timestamp(timestamp3), stream_id: @op1
    }

    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out1, ^out0]}}})
    assert out1.timestamp == event1.timestamp
    assert out1.value
    assert progressed_to == event1.timestamp

    Node.send_event(@processor, event2)

    assert_receive {_, {:update_input_stream, %{progressed_to: progressed_to, events: [
         ^out1, ^out0
       ]
     }}}
    assert progressed_to == event2.timestamp

    Node.send_event(@processor, event3)

    assert_receive {_, {:update_input_stream, %{progressed_to: progressed_to, events: [
         out3, out2, ^out1, ^out0
       ]
     }}}
    assert progressed_to == event3.timestamp
    assert out2.timestamp == Time.add(event2.timestamp, Time.from(@amount, :microseconds))
    refute out2.value
    assert out3.timestamp == event3.timestamp
    assert out3.value
    :ok = Node.stop(@processor)
  end
end
