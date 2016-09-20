defmodule TesslaServer.Computation.Lifted.NegTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Lifted.Neg
  alias TesslaServer.{Event, GenComputation, Registry}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest Neg

  setup do
    Registry.register @test
    Neg.start @processor, [@op1]
    :ok
  end

  test "Should compare latest Events and notify children" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])
    assert initial_output.type == :signal

    timestamp = DateTime.now
    event1 = %Event{timestamp: to_timestamp(timestamp), value: 1, stream_id: @op1}
    event2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: -2, stream_id: @op1}
    event3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 3, stream_id: @op1}

    GenComputation.send_event(@processor, event1)

    assert_receive {_, {:update_input_stream, %{progressed_to: progressed_to, events: [out0]}}}
    assert out0.value == -1
    assert progressed_to == event1.timestamp

    GenComputation.send_event(@processor, event2)

    assert_receive {_, {:update_input_stream, %{progressed_to: progressed_to, events: [out1, ^out0]}}}
    assert out1.value == 2
    assert progressed_to == event2.timestamp

    GenComputation.send_event(@processor, event3)

    assert_receive {_, {:update_input_stream, %{progressed_to: progressed_to, events: [out2, ^out1, ^out0]}}}
    assert out2.value == -3
    assert progressed_to == event3.timestamp

    :ok = GenComputation.stop @processor
  end
end
