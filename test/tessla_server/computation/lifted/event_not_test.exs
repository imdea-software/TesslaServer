defmodule TesslaServer.Computation.Lifted.EventNotTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Lifted.EventNot
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @op unique_integer
  @test unique_integer
  @processor unique_integer

  doctest EventNot

  setup do
    Registry.register @test
    EventNot.start @processor, [@op]
    :ok
  end

  test "Should compute not of latest Events and notify children" do
    GenComputation.add_child(@processor, @test)

    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    event1 = %Event{timestamp: timestamp1, stream_id: @op, value: true}
    event2 = %Event{
      timestamp: timestamp2, stream_id: @op, value: true
    }
    event3 = %Event{
      timestamp: timestamp3, stream_id: @op, type: :progress
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op, value: false
    }

    GenComputation.send_event(@processor, event1)

    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp1, value: false}}
    }

    GenComputation.send_event(@processor, event2)

    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp2, value: false}}
    }

    GenComputation.send_event(@processor, event3)

    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp3}}
    }

    GenComputation.send_event(@processor, event4)

    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp4, value: true}}
    }

    :ok = GenComputation.stop(@processor)
  end
end
