defmodule TesslaServer.Node.Filter.MergeTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Filter.Merge
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest Merge

  setup do
    :gproc.reg(gproc_tuple(@test))
    Merge.start @processor, [@op1, @op2]
    :ok
  end

  test "Should compute latest Event of either stream and notify children" do

    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])
    assert initial_output.type == :events

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_id: @op2}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), value: 3, stream_id: @op1}
    event4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 4, stream_id: @op1}
    event5 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 5, stream_id: @op2}

    Node.send_event(@processor, event1)

    refute_receive(_)

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out1]}}})
    assert(progressed_to == event1.timestamp)
    assert(out1.value == event1.value)

    Node.send_event(@processor, event3)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out2, ^out1]}}})
    assert(progressed_to == event2.timestamp)
    assert(out2.value == event2.value)

    Node.send_event(@processor, event4)
    refute_receive(_)

    Node.send_event(@processor, event5)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out4, out3, ^out2, ^out1]}}})
    assert(progressed_to == event4.timestamp)
    assert(out3.value == event3.value)
    assert(out4.value == event4.value)

    :ok = Node.stop @processor
  end
end
