defmodule TesslaServer.Node.Filter.ChangeOfTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Filter.ChangeOf
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest ChangeOf

  setup do
    :gproc.reg(gproc_tuple(@test))
    ChangeOf.start @processor, [@op1]
    :ok
  end

  test "Should emit an event whenever the signal changes" do

    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])

    timestamp = DateTime.now

    signal1 = %Event{value: 1, stream_id: @op1}
    signal2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_id: @op1}
    signal3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), value: 2, stream_id: @op1}

    Node.send_event(@processor, signal1)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to1,
        events: [out1]}}}
    )
    Node.send_event(@processor, signal2)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to2,
        events: [out2, ^out1]}}}
    )

    Node.send_event(@processor, signal3)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to3,
        events: [^out2, ^out1]}}}
    )

    assert progressed_to1 == signal1.timestamp
    assert progressed_to2 == signal2.timestamp
    assert progressed_to3 == signal3.timestamp

    assert out1.value == signal1.value
    assert out1.timestamp == signal1.timestamp
    assert out2.value == signal2.value
    assert out2.timestamp == signal2.timestamp

    :ok = Node.stop @processor
  end
end
