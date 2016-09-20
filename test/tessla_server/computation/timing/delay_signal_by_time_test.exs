defmodule TesslaServer.Computation.Timing.DelaySignalByTimeTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.DelaySignalByTime
  alias TesslaServer.{Event, GenComputation, Registry}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest DelaySignalByTime

  @op1 unique_integer
  @amount 1000
  @default 0
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    DelaySignalByTime.start @processor, [@op1], %{amount: @amount, default: @default}
    :ok
  end

  test "Should delay events by specified amount" do
    GenComputation.add_child(@processor, @test)

    assert_receive({_, {:update_input_stream, %{type: :signal, events: [out0]}}})
    assert out0.value == @default

    event1 = %Event{timestamp: {0, 1, 0}, stream_id: @op1, value: 1}
    event2 = %Event{timestamp: {0, 1, 10}, stream_id: @op1, value: 2}
    event3 = %Event{timestamp: {0, 1, 20}, stream_id: @op1, value: 3}
    event4 = %Event{timestamp: {0, 1, 1010}, stream_id: @op1, value: 4}
    event5 = %Event{timestamp: {0, 5, 0}, stream_id: @op1, value: 5}


    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [^out0]}}})
    assert progressed_to == event1.timestamp

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [^out0]}}})
    assert progressed_to == event2.timestamp

    GenComputation.send_event(@processor, event3)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [^out0]}}})
    assert progressed_to == event3.timestamp

    GenComputation.send_event(@processor, event4)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out2, out1, ^out0]}}})
    assert is_delayed(out1.timestamp, event1.timestamp)
    assert out1.value == event1.value
    assert is_delayed(out2.timestamp, event2.timestamp)
    assert out2.value == event2.value
    assert progressed_to == event4.timestamp

    GenComputation.send_event(@processor, event5)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to,
        events: [out4, out3, ^out2, ^out1, ^out0]}}})
    assert is_delayed(out3.timestamp, event3.timestamp)
    assert out3.value == event3.value
    assert is_delayed(out4.timestamp, event4.timestamp)
    assert out4.value == event4.value
    assert progressed_to == event5.timestamp

    :ok = GenComputation.stop(@processor)
  end

  @spec is_delayed(Timex.Types.timestamp, Timex.Types.timestamp) :: boolean
  defp is_delayed(time1, time2) do
    Time.diff(time1, time2) == Time.from(@amount, :microseconds)
  end
end
