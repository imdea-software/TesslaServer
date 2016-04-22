defmodule TesslaServer.Node.Lifted.AbsTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Abs
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Abs

  setup do
    state = %{stream_name: :abs, options: %{operand1: :number1, operand2: :number2}}
    processor = Abs.start state
    {:ok, processor: processor}
  end

  test "Should compute abs of latest Events and notify children", %{processor: processor} do
    name = :abs_test
    :gproc.reg(gproc_tuple(name))

    Node.add_child(processor, name)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: -2, stream_name: :number1}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 0, stream_name: :number1}

    Node.send_event(processor, event1)

    assert_receive({_, {:process, event}})

    assert(event.value == abs event1.value)

    Node.send_event(processor, event2)

    assert_receive({_, {:process, event}})

    assert(event.value == abs event2.value)

    Node.send_event(processor, event3)

    assert_receive({_, {:process, event}})

    assert(event.value == abs event3.value)
  end
end
