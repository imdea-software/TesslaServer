defmodule TesslaServer.Node.Lifted.EventAbsTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.EventAbs
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest EventAbs

  setup do
    :gproc.reg(gproc_tuple(@test))
    EventAbs.start @processor, [@op1]
    :ok
  end

  test "Should compute abs of latest Event and notify children" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: [], progressed_to: progressed_to, type: :events}}})
    assert(progressed_to == Time.zero)

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: -2, stream_id: @op1}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 0, stream_id: @op1}

    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: events}}})

    assert(hd(events).value == abs event1.value)

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: events}}})

    assert(hd(events).value == abs event2.value)

    Node.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{events: events}}})

    assert(hd(events).value == abs event3.value)

    :ok = Node.stop(@processor)
  end
end
