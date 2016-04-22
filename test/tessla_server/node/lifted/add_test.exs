defmodule TesslaServer.Node.Lifted.AddTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Add
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Add

  setup do
    state = %{stream_name: :adder, options: %{operand1: :number1, operand2: :number2}}
    adder = Add.start state
    {:ok, adder: adder}
  end

  test "Should add latest Events and notify children", %{adder: adder} do
    name = :add_test
    :gproc.reg(gproc_tuple(name))

    Node.add_child(adder, name)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_name: :number2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 3, stream_name: :number1}

    Node.send_event(adder, event1)
    Node.send_event(adder, event2)

    assert_receive({_, {:process, event}})

    assert(event.value == (event1.value + event2.value))

    Node.send_event(adder, event3)

    assert_receive({_, {:process, event}})

    assert(event.value == (event3.value + event2.value))
  end
end
