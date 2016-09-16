defmodule TesslaServer.Node.Filter.SampleTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Filter.Sample
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest Sample

  setup do
    :gproc.reg(gproc_tuple(@test))
    Sample.start @processor, [@op1, @op2]
    :ok
  end

  test "Should emit event with value of first stream whenever the second stream emits an event" do

    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])
    assert initial_output.type == :events

    timestamp = DateTime.now
    sample1 = %Event{timestamp: to_timestamp(timestamp), stream_id: @op2}
    sample2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 1)), stream_id: @op2}
    sample3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 3)), stream_id: @op2}
    sample4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 6)), stream_id: @op2}

    signal1 = %Event{value: 1, stream_id: @op1}
    signal2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_id: @op1}
    signal3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 3, stream_id: @op1}
    signal4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 5)), value: 4, stream_id: @op1}
    signal5 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 6)), value: 5, stream_id: @op1}

    Node.send_event(@processor, signal1)

    refute_receive(_)

    Node.send_event(@processor, sample1)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert(progressed_to == signal1.timestamp)

    Node.send_event(@processor, sample2)
    refute_receive(_)
    Node.send_event(@processor, sample3)
    refute_receive(_)
    Node.send_event(@processor, sample4)
    refute_receive(_)


    Node.send_event(@processor, signal2)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [sampled2, sampled1]}}})
    assert(progressed_to == signal2.timestamp)
    assert(sampled1.value == signal1.value)
    assert(sampled1.timestamp == sample1.timestamp)
    assert(sampled2.value == signal1.value)
    assert(sampled2.timestamp == sample2.timestamp)

    Node.send_event(@processor, signal3)
    assert_receive {_,
      {:update_input_stream, %{progressed_to: progressed_to, events: [sampled3, ^sampled2, ^sampled1]}}
    }
    assert(progressed_to == signal3.timestamp)
    assert(sampled3.value == signal2.value)
    assert(sampled3.timestamp == sample3.timestamp)

    Node.send_event(@processor, signal4)
    assert_receive {_,
     {:update_input_stream, %{progressed_to: progressed_to, events: [^sampled3, ^sampled2, ^sampled1]}}
    }
    assert(progressed_to == signal4.timestamp)

    Node.send_event(@processor, signal5)
    assert_receive {_,
     {:update_input_stream, %{progressed_to: progressed_to, events: [sampled4, ^sampled3, ^sampled2, ^sampled1]}}
    }
    assert(progressed_to == signal5.timestamp)
    assert(sampled4.value == signal5.value)
    assert(sampled4.timestamp == sample4.timestamp)

    :ok = Node.stop @processor
  end
end
