defmodule TesslaServer.Node.Filter.FilterTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Filter.Filter
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest Filter

  setup do
    :gproc.reg(gproc_tuple(@test))
    Filter.start @processor, [@op1, @op2]
    :ok
  end

  test "Should filter latest Event of first stream with second stream and notify children" do

    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now
    filter1 = %Event{value: true, stream_id: @op2}
    filter2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 1)), value: false, stream_id: @op2}
    filter3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), value: true, stream_id: @op2}
    filter4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 5)), value: false, stream_id: @op2}

    event1 = %Event{timestamp: to_timestamp(timestamp), value: 2, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 4, stream_id: @op1}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 4, stream_id: @op1}

    Node.send_event(@processor, filter1)

    refute_receive(_)

    Node.send_event(@processor, event1)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert(progressed_to == filter1.timestamp)

    Node.send_event(@processor, filter2)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [filtered1]}}})
    assert(progressed_to == event1.timestamp)
    assert(filtered1.value == event1.value)
    assert(filtered1.timestamp == event1.timestamp)

    Node.send_event(@processor, filter3)
    refute_receive(_)
    Node.send_event(@processor, filter4)
    refute_receive(_)

    Node.send_event(@processor, event2)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [^filtered1]}}})
    assert(progressed_to == event2.timestamp)

    Node.send_event(@processor, event3)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [filtered2, ^filtered1]}}})
    assert(progressed_to == event3.timestamp)
    assert(filtered2.value == event3.value)
    assert(filtered2.timestamp == event3.timestamp)

    :ok = Node.stop @processor
  end
end
