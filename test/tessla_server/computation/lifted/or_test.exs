defmodule TesslaServer.Computation.Lifted.OrTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Lifted.Or
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest Or

  setup do
    Registry.register @test
    Or.start @processor, [@op1, @op2]
    :ok
  end

  test "Should compute or of latest Events and notify children" do
    GenComputation.add_child(@processor, @test)

    timestamp0 = Duration.zero
    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))

    event1_0 = %Event{
      type: :change, timestamp: timestamp0, stream_id: @op1, value: true
    }
    event1_2 = %Event{
      type: :change, timestamp: timestamp2, stream_id: @op1, value: false
    }
    event1_3 = %Event{
      type: :change, timestamp: timestamp3, stream_id: @op1, value: true
    }
    event1_4 = %Event{
      type: :progress, timestamp: timestamp4, stream_id: @op1
    }

    event2_0 = %Event{
      type: :change, timestamp: timestamp0, stream_id: @op2, value: true
    }
    event2_1 = %Event{
      type: :change, timestamp: timestamp1, stream_id: @op2, value: false
    }
    event2_3 = %Event{
      type: :change, timestamp: timestamp3, stream_id: @op2, value: true
    }
    event2_4 = %Event{
      type: :progress, timestamp: timestamp4, stream_id: @op2
    }

    GenComputation.send_event(@processor, event1_0)
    GenComputation.send_event(@processor, event2_0)

    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^timestamp0, value: true}
    }}

    GenComputation.send_event(@processor, event2_1)

    GenComputation.send_event(@processor, event1_2)

    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp1}
    }}

    GenComputation.send_event(@processor, event2_3)

    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^timestamp2, value: false}
    }}

    GenComputation.send_event(@processor, event1_3)

    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^timestamp3, value: true}
    }}

    GenComputation.send_event(@processor, event1_4)
    GenComputation.send_event(@processor, event2_4)

    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp4}
    }}

    :ok = GenComputation.stop(@processor)
  end
end
