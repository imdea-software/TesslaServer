defmodule TesslaServer.Node.Aggregation.SignalMinimumTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Aggregation.SignalMinimum
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer


  doctest SignalMinimum

  setup do
    :gproc.reg(gproc_tuple(@test))
    SignalMinimum.start @processor, [@op1]
    :ok
  end

  test "Should take value of new event if it is smaller than previous minimum" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: [], type: :signal}}})
    timestamp = DateTime.now
    event1 = %Event{value: 4, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(timestamp), value: 3, stream_id: @op1}

    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: events}}})

    assert(hd(events).value == event1.value)

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: events}}})
    assert(hd(events).value == event2.value)

    :ok = Node.stop(@processor)
  end

  test "Should keep previous value if new value is bigger" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: [], type: :signal}}})
    timestamp = DateTime.now
    event1 = %Event{value: 4, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(timestamp), value: 5, stream_id: @op1}

    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: events}}})

    last_event = hd(events)
    assert(last_event.value == event1.value)

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: events}}})

    new_event = hd(events)
    assert(new_event == last_event)
    assert(progressed_to == event2.timestamp)

    :ok = Node.stop(@processor)
  end
end
