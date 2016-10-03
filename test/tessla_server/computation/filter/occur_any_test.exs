defmodule TesslaServer.Computation.Filter.OccurAnyTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Filter.OccurAny
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest OccurAny

  setup do
    Registry.register @test
    OccurAny.start @processor, [@op1, @op2]
    :ok
  end

  test "Should emit event whenever an event occurs on one input stream" do


    GenComputation.add_child(@processor, @test)

    timestamp1 = Duration.now
    timestamp2 = Duration.add timestamp1, Duration.from_seconds 2
    timestamp3 = Duration.add timestamp1, Duration.from_seconds 3
    timestamp4 = Duration.add timestamp1, Duration.from_seconds 4

    event1 = %Event{timestamp: timestamp1, value: 1, stream_id: @op1}
    event2 = %Event{timestamp: timestamp2, value: 2, stream_id: @op2}
    event3 = %Event{timestamp: timestamp3, type: :progress, stream_id: @op1}
    event4 = %Event{timestamp: timestamp3, type: :progress, stream_id: @op2}
    event5 = %Event{timestamp: timestamp4, value: 5, stream_id: @op1}
    event6 = %Event{timestamp: timestamp4, type: :progress, stream_id: @op2}


    GenComputation.send_event(@processor, event1)

    GenComputation.send_event(@processor, event2)

    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp1}
    }}

    GenComputation.send_event(@processor, event3)
    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp2}
    }}

    GenComputation.send_event(@processor, event4)
    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp3}
    }}

    GenComputation.send_event(@processor, event5)
    GenComputation.send_event(@processor, event6)
    assert_receive {_, {:process,
      %Event{type: :event, timestamp: ^timestamp4}
    }}

    :ok = GenComputation.stop @processor
  end
end
