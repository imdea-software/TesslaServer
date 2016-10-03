defmodule TesslaServer.Computation.Lifted.NegTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Lifted.Neg
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest Neg

  setup do
    Registry.register @test
    Neg.start @processor, [@op1]
    :ok
  end

  test "Should compare latest Events and notify children" do
    GenComputation.add_child(@processor, @test)

    timestamp0 = Duration.zero
    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    event0 = %Event{timestamp: timestamp0, value: 0, stream_id: @op1, type: :change}
    event1 = %Event{timestamp: timestamp1, value: 4, stream_id: @op1, type: :change}
    event2 = %Event{
      timestamp: timestamp2, value: -6, stream_id: @op1, type: :change
    }
    event3 = %Event{
      timestamp: timestamp3, value: 6, stream_id: @op1, type: :change
    }
    event4 = %Event{
      timestamp: timestamp4, stream_id: @op1, type: :progress
    }


    GenComputation.send_event(@processor, event0)
    assert_receive {_, {:process,
     %Event{type: :change, timestamp: ^timestamp0, value: 0}
    }}

    GenComputation.send_event(@processor, event1)

    assert_receive {_, {:process,
     %Event{type: :change, timestamp: ^timestamp1, value: -4}
    }}

    GenComputation.send_event(@processor, event2)

    assert_receive {_, {:process,
     %Event{type: :change, timestamp: ^timestamp2, value: 6}
    }}

    GenComputation.send_event(@processor, event3)

    assert_receive {_, {:process,
     %Event{type: :change, timestamp: ^timestamp3, value: -6}
    }}

    GenComputation.send_event(@processor, event4)

    assert_receive {_, {:process,
     %Event{type: :progress, timestamp: ^timestamp4}
    }}

    :ok = GenComputation.stop(@processor)
  end
end
