defmodule TesslaServer.Computation.Filter.ChangeOfTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Filter.ChangeOf
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @op1 unique_integer
  @test unique_integer
  @processor unique_integer

  doctest ChangeOf

  setup do
    Registry.register @test
    ChangeOf.start @processor, [@op1]
    :ok
  end

  test "Should emit an event whenever the signal changes" do

    GenComputation.add_child(@processor, @test)

    timestamp0 = Duration.zero
    timestamp1 = Duration.now
    timestamp2 = Duration.add timestamp1, Duration.from_seconds 2
    timestamp3 = Duration.add timestamp1, Duration.from_seconds 3

    signal0 = %Event{value: 1, stream_id: @op1}
    signal1 = %Event{timestamp: timestamp1, value: 2, stream_id: @op1}
    signal2 = %Event{timestamp: timestamp2, type:  :progress, stream_id: @op1}
    signal3 = %Event{timestamp: timestamp3, value: 1, stream_id: @op1}

    GenComputation.send_event(@processor, signal0)
    assert_receive {_, {:process, %Event{
       value: 1, type: :event, timestamp:   ^timestamp0
     }}}

    GenComputation.send_event(@processor, signal1)
    assert_receive {_, {:process, %Event{
       value: 2, type: :event, timestamp: ^timestamp1
     }}}

    GenComputation.send_event(@processor, signal2)
    assert_receive {_, {:process, %Event{
       type: :progress, timestamp: ^timestamp2
     }}}

    GenComputation.send_event(@processor, signal3)
    assert_receive {_, {:process, %Event{
       value: 1, type: :event, timestamp: ^timestamp3
     }}}

    :ok = GenComputation.stop @processor
  end
end
