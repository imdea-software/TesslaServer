defmodule TesslaServer.Computation.Lifted.SignalAbsTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Lifted.SignalAbs
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @op unique_integer
  @test unique_integer
  @processor unique_integer

  doctest SignalAbs

  setup do
    Registry.register @test
    SignalAbs.start @processor, [@op]
    :ok
  end

  test "Should compute abs of latest Event and notify children" do
    GenComputation.add_child(@processor, @test)

    timestamp0 = Duration.zero
    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    event0 = %Event{timestamp: timestamp0, stream_id: @op, value: -1, type: :change}
    event1 = %Event{timestamp: timestamp1, stream_id: @op, value: 1, type: :change}
    event2 = %Event{
      timestamp: timestamp2, stream_id: @op, value: -3, type: :change
    }
    event3 = %Event{
      timestamp: timestamp3, stream_id: @op, type: :progress
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op, value: -4, type: :change
    }

    GenComputation.send_event(@processor, event0)
    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^timestamp0, value: 1}}
    }

    GenComputation.send_event(@processor, event1)

    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp1}}
    }

    GenComputation.send_event(@processor, event2)

    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^timestamp2, value: 3}}
    }

    GenComputation.send_event(@processor, event3)

    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp3}}
    }

    GenComputation.send_event(@processor, event4)

    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^timestamp4, value: 4}}
    }

    :ok = GenComputation.stop(@processor)
  end
end
