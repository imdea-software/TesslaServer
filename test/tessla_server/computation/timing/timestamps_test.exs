defmodule TesslaServer.Computation.Timing.TimestampsTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.Timestamps
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  doctest Timestamps

  @op unique_integer
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    Timestamps.start @processor, [@op]
    :ok
  end

  test "should emit timestamp of every received event" do
    GenComputation.add_child(@processor, @test)

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))

    event1 = %Event{timestamp: timestamp1, stream_id: @op, value: 1}
    event2 = %Event{
      timestamp: timestamp2, stream_id: @op, type: :progress
    }
    event3 = %Event{
      timestamp: timestamp3, stream_id: @op, value: 4
    }

    GenComputation.send_event(@processor, event1)

    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp1, value: ^timestamp1}}
    }

    GenComputation.send_event(@processor, event2)

    assert_receive {_, {:process,
      %Event{timestamp: ^timestamp2, type: :progress}}
    }

    GenComputation.send_event(@processor, event3)

    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp3, value: ^timestamp3}}
    }

    :ok = GenComputation.stop(@processor)
  end
end
