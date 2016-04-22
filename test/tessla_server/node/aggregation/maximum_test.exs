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
    :gproc.reg(gproc_tuple(:maximum_test))
    state = %{stream_name: :maximum, options: %{operand1: :number, default: @default_value}}
    processor = Maximum.start state
    {:ok, processor: processor}
  end

  test "Should take value of new event if it is bigger than previous maximum" , %{processor: processor} do

    name = :maximum_test
    Node.add_child(processor, name)
    assert_receive({_, {:process, event}})
    assert(event.value == @default_value)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_name: :number}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: -2, stream_name: :number}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 0, stream_name: :number}

    # Node.send_event(processor, event1)

    # assert_receive({_, {:process, event}})

    # assert(event.value == event1.value)

    # Node.send_event(processor, event2)

    # assert_receive({_, {:process, event}})

    # assert(event.value == abs event2.value)

    # Node.send_event(processor, event3)

    # assert_receive({_, {:process, event}})

    # assert(event.value == abs event3.value)
  end
  test "Should keep previous value if new value is smaller" , %{processor: processor} do
    flunk "Not implemented"
  end
  test "Should keep default value until bigger value occurs" , %{processor: processor} do
    flunk "Not implemented"
  end
end
