defmodule TesslaServer.Computation.Aggregation.EventCountTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Aggregation.EventCount
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  doctest EventCount

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    EventCount.start @processor, [@op1]
    :ok
  end

  test "Should increment eventcount on every new event" do
    GenComputation.add_child(@processor, @test)
    assert_receive({_, {:update_input_stream, %{type: :signal, events: [out0]}}})
    assert(out0.value == 0)

    timestamp = Duration.now

    event1 = %Event{timestamp: timestamp, stream_id: @op1}
    event2 = %Event{
      timestamp: Duration.add(timestamp, Duration.from_seconds(2)), stream_id: @op1
    }

    GenComputation.send_event(@processor, event1)

    assert_receive({_, {:update_input_stream, %{events: [out1, ^out0]}}})
    assert out1.timestamp == event1.timestamp
    assert out1.value == 1

    GenComputation.send_event(@processor, event2)

    assert_receive({_, {:update_input_stream, %{events: [out2, ^out1, ^out0]}}})
    assert out2.value == 2
    assert out2.timestamp == event2.timestamp

    :ok = GenComputation.stop(@processor)
  end
end
