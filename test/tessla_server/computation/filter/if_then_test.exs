defmodule TesslaServer.Computation.Filter.IfThenTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Filter.IfThen
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest IfThen

  setup do
    Registry.register @test
    IfThen.start @processor, [@op1, @op2]
    :ok
  end

  test "Should emit event with value of second stream whenever the first stream emits an event" do

    GenComputation.add_child(@processor, @test)

    timestamp0 = Duration.now
    timestamp1 = Duration.add timestamp0, Duration.from_seconds 1
    timestamp2 = Duration.add timestamp0, Duration.from_seconds 2
    timestamp3 = Duration.add timestamp0, Duration.from_seconds 3
    timestamp4 = Duration.add timestamp0, Duration.from_seconds 4
    timestamp5 = Duration.add timestamp0, Duration.from_seconds 5
    timestamp6 = Duration.add timestamp0, Duration.from_seconds 6

    sample1 = %Event{timestamp: timestamp1, stream_id: @op1}
    sample3 = %Event{timestamp: timestamp3, stream_id: @op1, type: :progress}
    sample4 = %Event{timestamp: timestamp4, stream_id: @op1}
    sample6 = %Event{timestamp: timestamp6, stream_id: @op1}

    change0 = %Event{value: 1, stream_id: @op2, type: :change}
    change2 = %Event{timestamp: timestamp2, value: 2, stream_id: @op2, type: :change}
    change4 = %Event{timestamp: timestamp4, type: :progress, stream_id: @op2}
    change5 = %Event{timestamp: timestamp5, value: 5, stream_id: @op2, type: :change}
    change6 = %Event{timestamp: timestamp6, value: 6, stream_id: @op2, type: :change}

    GenComputation.send_event(@processor, change0)

    refute_receive(_)

    GenComputation.send_event(@processor, sample1)
    GenComputation.send_event(@processor, sample3)
    GenComputation.send_event(@processor, sample4)
    GenComputation.send_event(@processor, sample6)
    assert_receive({_, {:process, out0}})
    assert out0.type == :progress
    assert out0.timestamp == Duration.zero

    GenComputation.send_event(@processor, change2)
    assert_receive({_, {:process, out1}})
    assert out1.type == :event
    assert out1.value == 1
    assert out1.timestamp == timestamp1

    assert_receive({_, {:process, progress2}})
    assert progress2.type == :progress
    assert progress2.timestamp == timestamp2

    GenComputation.send_event @processor, change4
    assert_receive({_, {:process, progress3}})
    assert progress3.type == :progress
    assert progress3.timestamp == timestamp3

    assert_receive({_, {:process, out4}})
    assert out4.type == :event
    assert out4.value == change2.value
    assert out4.timestamp == timestamp4

    GenComputation.send_event(@processor, change5)
    assert_receive({_, {:process, progress5}})
    assert progress5.type == :progress
    assert progress5.timestamp == timestamp5

    GenComputation.send_event(@processor, change6)
    assert_receive({_, {:process, out6}})
    assert out6.type == :event
    assert out6.value == 6
    assert out6.timestamp == timestamp6

    refute_receive _

    :ok = GenComputation.stop @processor
  end
end
