defmodule TesslaServer.Node.Lifted.AbsTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Abs
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Abs

  @op1 :number
  @test :abs_test
  @processor :abs

  setup do
    :gproc.reg(gproc_tuple(@test))
    Abs.start @processor, [@op1]
    :ok
  end

  test "Should compute abs of latest Event and notify children" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_name: @op1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: -2, stream_name: @op1}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 0, stream_name: @op1}

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