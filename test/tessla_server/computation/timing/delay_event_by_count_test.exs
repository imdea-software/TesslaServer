defmodule TesslaServer.Computation.Timing.DelayEventByCountTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.DelayEventByCount
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  doctest DelayEventByCount

  @op unique_integer
  @count 2
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    DelayEventByCount.start @processor, [@op], %{count: @count}
    :ok
  end

  test "Should delay events by specified count" do
    GenComputation.add_child(@processor, @test)

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))
    timestamp5 = Duration.add(timestamp1, Duration.from_seconds(4))

    event1 = %Event{timestamp: timestamp1, stream_id: @op, value: 1}
    event2 = %Event{
      timestamp: timestamp2, stream_id: @op, value: 2
    }
    event3 = %Event{
      timestamp: timestamp3, stream_id: @op, value: 3
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op, type: :progress
    }
    event5 = %Event{
      timestamp: timestamp5, stream_id: @op, value: 5
    }

    GenComputation.send_event(@processor, event1)

    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp1}}
    }

    GenComputation.send_event(@processor, event2)

    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp2}}
    }

    GenComputation.send_event(@processor, event3)

    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp3, value: 1}}
    }

    GenComputation.send_event(@processor, event4)

    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp4}}
    }

    GenComputation.send_event(@processor, event5)

    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp5, value: 2}}
    }

    :ok = GenComputation.stop(@processor)
  end
end
