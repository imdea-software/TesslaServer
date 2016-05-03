defmodule TesslaServer.Node.Lifted.OrTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Or
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [shift: 2, to_timestamp: 1]

  doctest Or

  setup do
    name = :or_test
    :gproc.reg(gproc_tuple(name))
    state = %{stream_name: :or, options: %{operand1: :boolean1, operand2: :boolean2}}
    {:ok, state: state, name: name}
  end

  test "Should compute or of latest Events and notify children", %{state: state, name: name} do
    processor = Or.start state

    Node.add_child(processor, name)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: true, stream_name: :boolean1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: false, stream_name: :boolean2}
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
    assert(hd(events).value == event1.value or event2.value)

    Node.send_event(processor, event4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event3.timestamp)
    assert(hd(events).value == (event3.value or event4.value))

    :ok = Node.stop processor
  end
end
