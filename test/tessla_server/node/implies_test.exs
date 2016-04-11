defmodule TesslaServer.Node.ImpliesTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Implies
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Implies

  setup do
    state = %{stream_name: :implies, options: %{operand1: :number1, operand2: :number2}}
    comparer = Implies.start state
    {:ok, comparer: comparer}
  end

  test "Should compute implies of latest Events and notify children", %{comparer: comparer} do
    name = :implies_test
    :gproc.reg(gproc_tuple(name))

    Node.add_child(comparer, name)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: true, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: false, stream_name: :number2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: false, stream_name: :number1}

    Node.send_event(comparer, event1)
    Node.send_event(comparer, event2)

    assert_receive({_, {:process, event}})

    refute(event.value)

    Node.send_event(comparer, event3)

    assert_receive({_, {:process, event}})

    assert(event.value)
  end
end
