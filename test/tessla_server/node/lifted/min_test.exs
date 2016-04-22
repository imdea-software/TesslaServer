defmodule TesslaServer.Node.Lifted.MinTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Min
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Min

  setup do
    state = %{stream_name: :min, options: %{operand1: :number1, operand2: :number2}}
    comparer = Min.start state
    {:ok, comparer: comparer}
  end

  test "Should compute min of latest Events and notify children", %{comparer: comparer} do
    name = :min_test
    :gproc.reg(gproc_tuple(name))

    Node.add_child(comparer, name)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_name: :number2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 3, stream_name: :number1}

    Node.send_event(comparer, event1)
    Node.send_event(comparer, event2)

    assert_receive({_, {:process, event}})

    assert(event.value == Enum.min [event1.value | [event2.value]])

    Node.send_event(comparer, event3)

    assert_receive({_, {:process, event}})

    assert(event.value == Enum.min [event3.value | [event2.value]])
  end
end
