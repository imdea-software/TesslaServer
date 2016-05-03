defmodule TesslaServer.Node.Lifted.AddTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Add
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Add

  setup do
    name = :add_test
    :gproc.reg(gproc_tuple(name))
    state = %{stream_name: :adder, options: %{operand1: :number1, operand2: :number2}}
    {:ok, state: state, name: name}
  end

  test "Should add latest Events and notify children", %{state: state, name: name} do
    adder = Add.start state

    Node.add_child(adder, name)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_name: :number2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 3, stream_name: :number1}
    event4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 2, stream_name: :number2}

    Node.send_event(adder, event1)

    refute_receive(_)

    Node.send_event(adder, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert(progressed_to == event1.timestamp)

    Node.send_event(adder, event3)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event2.timestamp)
    assert(hd(events).value == event1.value + event2.value)

    Node.send_event(adder, event4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event3.timestamp)
    assert(hd(events).value == event3.value + event4.value)

    :ok = Node.stop adder
  end
end
