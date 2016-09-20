defmodule TesslaServer.Computation.Lifted.SignalNotTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Lifted.SignalNot
  alias TesslaServer.{Event, GenComputation}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op unique_integer
  @test unique_integer
  @processor unique_integer

  doctest SignalNot

  setup do
    Registry.register @test
    SignalNot.start @processor, [@op]
    :ok
  end

  test "Should compute not of latest Events and notify children" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])
    assert initial_output.type == :signal

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: false, stream_id: @op}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: true, stream_id: @op}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), value: false, stream_id: @op}

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [event]}}})
    assert(progressed_to == event1.timestamp)
    assert event.value

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event2.timestamp)
    refute hd(events).value

    GenComputation.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})
    assert(progressed_to == event3.timestamp)
    assert hd(events).value

    :ok = GenComputation.stop @processor
  end
end
