defmodule TesslaServer.Node.Lifted.AndTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.And
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest And

  setup do
    :gproc.reg(gproc_tuple(@test))
    And.start @processor, [@op1, @op2]
    :ok
  end

  test "Should compute and of latest Events and notify children" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: true, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: true, stream_id: @op2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: false, stream_id: @op1}
    event4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: false, stream_id: @op2}

    Node.send_event(@processor, event1)

    refute_receive(_)

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert(progressed_to == event1.timestamp)

    Node.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event2.timestamp)
    assert(hd(events).value == event1.value and event2.value)

    Node.send_event(@processor, event4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event3.timestamp)
    assert(hd(events).value == (event3.value and event4.value))

    :ok = Node.stop @processor
  end
end
