defmodule TesslaServer.Node.Lifted.MulTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Mul
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Mul

  setup do
    name = :mul_test
    :gproc.reg(gproc_tuple(name))
    state = %{stream_name: :mul, options: %{operand1: :number1, operand2: :number2}}
    {:ok, state: state, name: name}
  end

  test "Should compute product of latest Events and notify children", %{state: state, name: name} do
    processor = Mul.start state

    Node.add_child(processor, name)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_name: :number2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), value: 3, stream_name: :number1}
    event4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 4, stream_name: :number2}

    Node.send_event(processor, event1)

    refute_receive(_)

    Node.send_event(processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert(progressed_to == event1.timestamp)

    Node.send_event(processor, event3)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event2.timestamp)
    assert(hd(events).value == (event1.value * event2.value))

    Node.send_event(processor, event4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event3.timestamp)
    assert(hd(events).value == (event2.value * event3.value))

    :ok = Node.stop processor
  end
end
