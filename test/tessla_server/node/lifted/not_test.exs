defmodule TesslaServer.Node.Lifted.NotTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Lifted.Not
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Not

  setup do
    state = %{stream_name: :not, options: %{operand1: :number1, operand2: :number2}}
    processor = Not.start state
    {:ok, processor: processor}
  end

  test "Should compute negation of latest Event and notify children", %{processor: processor} do
    name = :not_test
    :gproc.reg(gproc_tuple(name))

    Node.add_child(processor, name)
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: true, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: false, stream_name: :number1}

    Node.send_event(processor, event1)

    assert_receive({_, {:process, event}})

    refute(event.value)

    Node.send_event(processor, event2)

    assert_receive({_, {:process, event}})

    assert(event.value)
  end
end
