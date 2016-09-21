defmodule TesslaServer.Computation.Lifted.DivTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Lifted.Div
  alias TesslaServer.{Event, GenComputation, Registry}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest Div

  setup do
    Registry.register @test
    Div.start @processor, [@op1, @op2]
    :ok
  end

  test "Should compute and of latest Events and notify children" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: [], progressed_to: progressed_to, type: :signal}}})
    assert(progressed_to == Time.zero)

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 4, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_id: @op2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 3, stream_id: @op1}
    event4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 5, stream_id: @op2}

    GenComputation.send_event(@processor, event1)

    refute_receive(_)

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert(progressed_to == event1.timestamp)

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event2.timestamp)
    assert(hd(events).value == event1.value / event2.value)

    GenComputation.send_event(@processor, event4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event3.timestamp)
    assert(hd(events).value == (event3.value / event4.value))

    :ok = GenComputation.stop @processor
  end
end