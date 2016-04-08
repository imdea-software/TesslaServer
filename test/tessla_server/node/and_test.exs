defmodule TesslaServer.Node.AndTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.And
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest And

  setup do
    state = %{stream_name: :and, options: %{operand1: :number1, operand2: :number2}}
    comparer = And.start state
    {:ok, comparer: comparer}
  end

  test "Should compute and of latest Events and notify children", %{comparer: comparer} do
    name = :and_test
    :gproc.reg(gproc_tuple(name))

    Node.add_child(comparer, name)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: true, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: true, stream_name: :number2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: false, stream_name: :number1}

    Node.send_event(comparer, event1)
    Node.send_event(comparer, event2)

    assert_receive({_, {:process, event}})

    assert(event.value == (event1.value && event2.value))

    Node.send_event(comparer, event3)

    assert_receive({_, {:process, event}})

    assert(event.value == (event2.value && event3.value))
  end
end
