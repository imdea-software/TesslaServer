defmodule TesslaServer.Node.Lifted.NotTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Not
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Not

  setup do
    name = :not_test
    :gproc.reg(gproc_tuple(name))
    state = %{stream_name: :not, options: %{operand1: :boolean}}
    {:ok, state: state, name: name}
  end

  test "Should compute not of latest Events and notify children", %{state: state, name: name} do
    processor = Not.start state

    Node.add_child(processor, name)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: false, stream_name: :boolean}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: true, stream_name: :boolean}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), value: false, stream_name: :boolean}

    Node.send_event(processor, event1)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [event]}}})
    assert(progressed_to == event1.timestamp)
    assert event.value

    Node.send_event(processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event2.timestamp)
    refute hd(events).value

    Node.send_event(processor, event3)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event3.timestamp)
    assert hd(events).value

    :ok = Node.stop processor
  end
end
