defmodule TesslaServer.Node.Filter.OccurAllTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Filter.OccurAll
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest OccurAll

  setup do
    :gproc.reg(gproc_tuple(@test))
    OccurAll.start @processor, [@op1, @op2]
    :ok
  end

  test "Should emit event whenever an event occurs on both input streams" do

    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])
    assert initial_output.type == :events

    timestamp = DateTime.now
    event1_1 = %Event{timestamp: to_timestamp(timestamp), stream_id: @op1}
    event1_2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 1)), stream_id: @op1}
    event1_3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), stream_id: @op1}

    event2_1 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 1)), stream_id: @op2}
    event2_2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), stream_id: @op2}
    event2_3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), stream_id: @op2}

    Node.send_event(@processor, event1_1)
    refute_receive _

    Node.send_event(@processor, event1_2)
    refute_receive _

    Node.send_event(@processor, event2_1)
    assert_receive {_, {:update_input_stream, %{progressed_to: progressed_to1, events: [out1]}}}
    assert out1.timestamp == event2_1.timestamp
    assert progressed_to1 == event2_1.timestamp

    Node.send_event(@processor, event1_3)
    refute_receive _

    Node.send_event(@processor, event2_2)
    assert_receive {_, {:update_input_stream, %{progressed_to: progressed_to2, events: [^out1]}}}
    assert progressed_to2 == event2_2.timestamp

    Node.send_event(@processor, event2_3)
    assert_receive {_, {:update_input_stream, %{progressed_to: progressed_to3, events: [out2, ^out1]}}}
    assert progressed_to3 == event2_3.timestamp
    assert out2.timestamp == event2_3.timestamp

    :ok = Node.stop @processor
  end
end
