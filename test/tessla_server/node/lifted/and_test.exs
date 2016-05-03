defmodule TesslaServer.Node.Lifted.AndTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.And
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest And

  setup do
    name = :and_test
    :gproc.reg(gproc_tuple(name))
    state = %{stream_name: :and, options: %{operand1: :boolean1, operand2: :boolean2}}
    {:ok, state: state, name: name}
  end

  test "Should compute and of latest Events and notify children", %{state: state, name: name} do
    processor = And.start state

    Node.add_child(processor, name)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: true, stream_name: :boolean1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: true, stream_name: :boolean2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: false, stream_name: :boolean1}
    event4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: false, stream_name: :boolean2}

    Node.send_event(processor, event1)

    refute_receive(_)

    Node.send_event(processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert(progressed_to == event1.timestamp)

    Node.send_event(processor, event3)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event2.timestamp)
    assert(hd(events).value == event1.value and event2.value)

    Node.send_event(processor, event4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event3.timestamp)
    assert(hd(events).value == (event3.value and event4.value))

    :ok = Node.stop processor
  end
end
