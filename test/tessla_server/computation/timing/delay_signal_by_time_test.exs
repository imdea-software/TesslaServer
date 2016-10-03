defmodule TesslaServer.Computation.Timing.DelaySignalByTimeTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Timing.DelaySignalByTime
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  doctest DelaySignalByTime

  @op unique_integer
  @amount 1000
  @default -1
  @test unique_integer
  @processor unique_integer

  setup do
    Registry.register @test
    DelaySignalByTime.start @processor, [@op], %{amount: @amount, default: @default}
    :ok
  end

  test "Should delay changes by specified amount" do
    GenComputation.add_child(@processor, @test)

    shift_duration = Duration.from_microseconds @amount

    timestamp0 = Duration.zero
    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    change0 = %Event{timestamp: timestamp0, stream_id: @op, value: @default, type: :change}
    change1 = %Event{timestamp: timestamp1, stream_id: @op, value: 1, type: :change}
    change2 = %Event{
      timestamp: timestamp2, stream_id: @op, value: 2, type: :change
    }
    change3 = %Event{
      timestamp: timestamp3, stream_id: @op, type: :progress
    }
    change4 = %Event{
      timestamp: timestamp4, stream_id: @op, value: 4, type: :change
    }

    GenComputation.send_event(@processor, change0)

    shifted_timestamp0 = Duration.add timestamp0, shift_duration
    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^timestamp0, value: @default}}
    }
    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^shifted_timestamp0}}
    }

    GenComputation.send_event(@processor, change1)

    shifted_timestamp1 = Duration.add timestamp1, shift_duration
    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^shifted_timestamp1, value: 1}}
    }

    GenComputation.send_event(@processor, change2)

    shifted_timestamp2 = Duration.add timestamp2, shift_duration
    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^shifted_timestamp2, value: 2}}
    }

    GenComputation.send_event(@processor, change3)

    shifted_timestamp3 = Duration.add timestamp3, shift_duration
    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^shifted_timestamp3}}
    }

    GenComputation.send_event(@processor, change4)

    shifted_timestamp4 = Duration.add timestamp4, shift_duration
    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^shifted_timestamp4, value: 4}}
    }

    :ok = GenComputation.stop(@processor)
  end
end
