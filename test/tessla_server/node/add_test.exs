defmodule TesslaServer.Node.AddTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.{State, Add, History}
  alias TesslaServer.{Event, Node}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]

  doctest Add

  setup do
    state = %{stream_name: :adder, options: %{operand1: :number1, operand2: :number2}}
    adder = Add.start state
    {:ok, adder: adder}
  end

  test "Should add latest Events", %{adder: adder} do
    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_name: :number1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 1, stream_name: :number2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 2, stream_name: :number1}

    Node.send_event(adder, event1)
    Node.send_event(adder, event2)

    output = Node.get_latest_output(adder)
    IO.puts inspect(output)

  end
end
