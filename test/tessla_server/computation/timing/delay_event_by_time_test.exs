defmodule TesslaServer.Computation.Timing.DelayEventByTimeTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.DelayEventByTime
  alias TesslaServer.{Event, GenComputation, Registry}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest DelayEventByTime

  @op1 unique_integer
  @amount 1000
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    DelayEventByTime.start @processor, [@op1], %{amount: @amount}
    :ok
  end

  test "Should delay events by specified amount" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: []}}})

    event0 = %Event{timestamp: {0, 1, 0}, stream_id: @op1, value: 0}
    event1 = %Event{timestamp: {0, 1, 10}, stream_id: @op1, value: 1}
    event2 = %Event{timestamp: {0, 1, 20}, stream_id: @op1, value: 2}
    event3 = %Event{timestamp: {0, 1, 1010}, stream_id: @op1, value: 3}
    event4 = %Event{timestamp: {0, 5, 0}, stream_id: @op1, value: 4}

    GenComputation.send_event(@processor, event0)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert progressed_to == event0.timestamp

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert progressed_to == event1.timestamp

    GenComputation.send_event(@processor, event2)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: []}}})
    assert progressed_to == event2.timestamp

    GenComputation.send_event(@processor, event3)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out1, out0]}}})
    assert is_delayed(out0.timestamp, event0.timestamp)
    assert out0.value == event0.value
    assert is_delayed(out1.timestamp, event1.timestamp)
    assert out1.value == event1.value
    assert progressed_to == event3.timestamp

    GenComputation.send_event(@processor, event4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out3, out2, ^out1, ^out0]}}})
    assert is_delayed(out2.timestamp, event2.timestamp)
    assert out2.value == event2.value
    assert is_delayed(out3.timestamp, event3.timestamp)
    assert out3.value == event3.value
    assert progressed_to == event4.timestamp

    :ok = GenComputation.stop(@processor)
  end

  @spec is_delayed(Timex.Types.timestamp, Timex.Types.timestamp) :: boolean
  defp is_delayed(time1, time2) do
    Time.diff(time1, time2) == Time.from(@amount, :microseconds)
  end
end
