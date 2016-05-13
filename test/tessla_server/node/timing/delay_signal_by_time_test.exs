defmodule TesslaServer.Node.Timing.DelaySignalByTimeTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Timing.DelaySignalByTime
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest DelaySignalByTime

  @op1 unique_integer
  @amount 10000
  @default 0
  @test unique_integer
  @processor unique_integer

  setup do
    :gproc.reg(gproc_tuple(@test))
    DelaySignalByTime.start @processor, [@op1], %{amount: @amount, default: @default}
    :ok
  end

  test "Should delay events by specified amount" do
    Node.add_child(@processor, @test)

    assert_receive({_, {:update_input_stream, %{type: :signal, events: [out0]}}})
    assert out0.value == @default

    event1 = %Event{timestamp: {0, 1, 0}, stream_id: @op1}
    event2 = %Event{
      timestamp: {0, 1, 5}, stream_id: @op1
    }
    event3 = %Event{
      timestamp: {0, 5, 0}, stream_id: @op1
    }

    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: [out1, ^out0]}}})
    assert is_delayed(out1.timestamp, event1.timestamp)

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: [out2, ^out1, ^out0]}}})
    assert is_delayed(out2.timestamp, event2.timestamp)

    Node.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{events: [out3, ^out2, ^out1, ^out0]}}})
    assert is_delayed(out3.timestamp, event3.timestamp)

    :ok = Node.stop(@processor)
  end

  @spec is_delayed(Timex.Types.timestamp, Timex.Types.timestamp) :: boolean
  defp is_delayed(time1, time2) do
    Time.diff(time1, time2) == Time.from(@amount, :microseconds)
  end
end
