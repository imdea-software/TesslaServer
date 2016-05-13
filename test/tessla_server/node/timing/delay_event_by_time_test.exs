defmodule TesslaServer.Node.Timing.DelayEventByTimeTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.Timing.DelayEventByTime
  alias TesslaServer.{Event, Node}

  import TesslaServer.Registry
  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
  import System, only: [unique_integer: 0]

  doctest DelayEventByTime

  @op1 unique_integer
  @amount 1000
  @test unique_integer
  @processor unique_integer

  setup do
    :gproc.reg(gproc_tuple(@test))
    DelayEventByTime.start @processor, [@op1], %{amount: @amount}
    :ok
  end

  test "Should delay events by specified amount" do
    Node.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{events: []}}})

    event1 = %Event{timestamp: {0, 1, 0}, stream_id: @op1}
    event2 = %Event{
      timestamp: {0, 1, 5}, stream_id: @op1
    }
    event3 = %Event{
      timestamp: {0, 5, 0}, stream_id: @op1
    }

    Node.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: [out0]}}})
    assert is_delayed(out0.timestamp, event1.timestamp)

    Node.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: [out1, ^out0]}}})
    assert is_delayed(out1.timestamp, event2.timestamp)

    Node.send_event(@processor, event3)

    assert_receive({_, {:update_input_stream, %{events: [out2, ^out1, ^out0]}}})
    assert is_delayed(out2.timestamp, event3.timestamp)

    :ok = Node.stop(@processor)
  end

  @spec is_delayed(Timex.Types.timestamp, Timex.Types.timestamp) :: boolean
  defp is_delayed(time1, time2) do
    Time.diff(time1, time2) == Time.from(@amount, :microseconds)
  end
end
