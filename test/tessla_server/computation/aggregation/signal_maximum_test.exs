defmodule TesslaServer.Computation.Aggregation.SignalMaximumTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Aggregation.SignalMaximum
  alias TesslaServer.{Event, GenComputation, Registry}

  import DateTime, only: [now: 0, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest SignalMaximum

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    SignalMaximum.start @processor, [@op1]
    :ok
  end

  test "Should take value of new event if it is bigger than previous maximum" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{type: :signal, events: []}}})
    timestamp = DateTime.now
    event1 = %Event{value: 6, stream_id: @op1}
    event2 = %Event{
      timestamp: to_timestamp(timestamp), value: 7, stream_id: @op1
    }

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: events}}})

    assert(hd(events).value == event1.value)

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: events}}})
    assert(hd(events).value == event2.value)

    :ok = GenComputation.stop(@processor)
  end

  test "Should keep previous value if new value is smaller" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: [], type: :signal}}})
    timestamp = DateTime.now
    event1 = %Event{value: 6, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(timestamp), value: 5, stream_id: @op1}

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: [last_event]}}})

    assert(last_event.value == event1.value)

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [^last_event]}}})

    assert(progressed_to == event2.timestamp)

    :ok = GenComputation.stop(@processor)
  end
end
