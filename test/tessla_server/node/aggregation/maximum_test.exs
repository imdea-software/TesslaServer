defmodule TesslaServer.Node.Aggregation.MaximumTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Aggregation.Maximum
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Maximum

  @default_value 5

  setup do
    name = :maximum_test
    :gproc.reg(gproc_tuple(name))
    state = %{stream_name: :maximum, options: %{operand1: :number, default: @default_value}}
    {:ok, state: state, name: name}
  end

  test "Should take value of new event if it is bigger than previous maximum", %{state: state, name: name} do
    processor = Maximum.start state

    Node.add_child(processor, name)
    assert_receive({_, {:update_input_stream, %{events: events}}})
    assert(hd(events).value == @default_value)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 6, stream_name: :number}
    event2 = %Event{
      timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 7, stream_name: :number
    }

    Node.send_event(processor, event1)

    assert_receive({_, {:update_input_stream, %{events: events}}})

    assert(hd(events).value == event1.value)

    Node.send_event(processor, event2)

    assert_receive({_, {:update_input_stream, %{events: events}}})
    assert(hd(events).value == event2.value)

    :ok = Node.stop(processor)
  end

  test "Should keep previous value if new value is smaller" , %{state: state} do
    processor = Maximum.start state
    name = :maximum_test
    Node.add_child(processor, name)
    assert_receive({_, {:update_input_stream, %{events: events}}})
    assert(hd(events).value == @default_value)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 6, stream_name: :number}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 5, stream_name: :number}

    Node.send_event(processor, event1)

    assert_receive({_, {:update_input_stream, %{events: events}}})

    last_event = hd(events)
    assert(last_event.value == event1.value)

    Node.send_event(processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})

    new_event = hd(events)
    assert(new_event == last_event)
    assert(progressed_to == event2.timestamp)

    :ok = Node.stop(processor)
  end
  test "Should keep default value until bigger value occurs" , %{state: state} do
    processor = Maximum.start state
    name = :maximum_test
    Node.add_child(processor, name)
    assert_receive({_, {:update_input_stream, %{events: events}}})

    first_event = hd(events)
    assert(first_event.value == @default_value)

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 4, stream_name: :number}
    event2 = %Event{
      timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 5, stream_name: :number
    }
    event3 = %Event{
      timestamp: to_timestamp(shift(timestamp, seconds: 3)), value: 6, stream_name: :number
    }

    Node.send_event(processor, event1)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(hd(events) == first_event)
    assert(progressed_to == event1.timestamp)

    Node.send_event(processor, event2)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(hd(events) == first_event)
    assert(progressed_to == event2.timestamp)

    Node.send_event(processor, event3)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    refute(hd(events) == first_event)
    assert(progressed_to == event3.timestamp)
    assert(hd(events).value == event3.value)

    :ok = Node.stop(processor)
  end
end
