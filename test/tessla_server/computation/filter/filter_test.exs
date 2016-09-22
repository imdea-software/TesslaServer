defmodule TesslaServer.Computation.Filter.FilterTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Filter.Filter
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @op2 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest Filter

  setup do
    Registry.register @test
    Filter.start @processor, [@op1, @op2]
    :ok
  end

  test "Should filter latest Event of first stream with second stream and notify children" do

    GenComputation.add_child(@processor, @test)

    timestamp0 = Duration.zero
    timestamp1 = Duration.now
    timestamp2 = Duration.add(timestamp1, Duration.from_seconds(1))
    timestamp3 = Duration.add(timestamp1, Duration.from_seconds(2))
    timestamp4 = Duration.add(timestamp1, Duration.from_seconds(3))
    timestamp5 = Duration.add(timestamp1, Duration.from_seconds(4))

    filter0 = %Event{value: true, stream_id: @op2}
    filter1 = %Event{timestamp: timestamp1, value: false, stream_id: @op2, type: :change}
    filter2 = %Event{timestamp: timestamp2, value: true, stream_id: @op2, type: :change}
    filter3 = %Event{timestamp: timestamp3, type: :progress, stream_id: @op2}
    filter5 = %Event{timestamp: timestamp5, value: :false, stream_id: @op2, type: :change}

    event1 = %Event{timestamp: timestamp1, stream_id: @op1}
    event2 = %Event{timestamp: timestamp2, value: 2, stream_id: @op1}
    event3 = %Event{timestamp: timestamp3, value: 3, stream_id: @op1}
    event4 = %Event{timestamp: timestamp4, type: :progress, stream_id: @op1}
    event5 = %Event{timestamp: timestamp5, value: 5, stream_id: @op1}

    GenComputation.send_event(@processor, filter0)

    refute_receive(_)

    GenComputation.send_event(@processor, event1)
    assert_receive {_, {:process,
      %Event{
        type: :progress, timestamp: ^timestamp0
      }}}


    GenComputation.send_event(@processor, filter1)
    assert_receive {_, {:process,
      %Event{
        type: :progress, timestamp: ^timestamp1
      }}}

    GenComputation.send_event(@processor, filter2)
    GenComputation.send_event(@processor, event2)
    assert_receive {_, {:process,
      %Event{
        type: :event, timestamp: ^timestamp2, value: 2
      }}}

    GenComputation.send_event(@processor, event3)
    GenComputation.send_event(@processor, filter3)
    assert_receive {_, {:process,
      %Event{
        type: :event, timestamp: ^timestamp3, value: 3
      }}}

    GenComputation.send_event(@processor, event4)
    GenComputation.send_event(@processor, event5)
    GenComputation.send_event(@processor, filter5)

    assert_receive {_, {:process,
      %Event{
        type: :progress, timestamp: ^timestamp4
      }}}
    assert_receive {_, {:process,
      %Event{
        type: :progress, timestamp: ^timestamp5
      }}}

    :ok = GenComputation.stop @processor
  end
end
