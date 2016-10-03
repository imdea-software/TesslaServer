defmodule TesslaServer.Computation.Timing.DelayEventByTimeTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.DelayEventByTime
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  doctest DelayEventByTime

  @op unique_integer
  @amount 1000
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    DelayEventByTime.start @processor, [@op], %{amount: @amount}
    :ok
  end

  test "Should delay events by specified amount" do
    GenComputation.add_child(@processor, @test)

    shift_duration = Duration.from_microseconds @amount

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    event1 = %Event{timestamp: timestamp1, stream_id: @op, value: 1}
    event2 = %Event{
      timestamp: timestamp2, stream_id: @op, value: 2
    }
    event3 = %Event{
      timestamp: timestamp3, stream_id: @op, type: :progress
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op, value: 4
    }

    GenComputation.send_event(@processor, event1)

    shifted_timestamp1 = Duration.add timestamp1, shift_duration
    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^shifted_timestamp1, value: 1}}
    }

    GenComputation.send_event(@processor, event2)

    shifted_timestamp2 = Duration.add timestamp2, shift_duration
    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^shifted_timestamp2, value: 2}}
    }

    GenComputation.send_event(@processor, event3)

    shifted_timestamp3 = Duration.add timestamp3, shift_duration
    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^shifted_timestamp3}}
    }

    GenComputation.send_event(@processor, event4)

    shifted_timestamp4 = Duration.add timestamp4, shift_duration
    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^shifted_timestamp4, value: 4}}
    }

    :ok = GenComputation.stop(@processor)
  end
end
