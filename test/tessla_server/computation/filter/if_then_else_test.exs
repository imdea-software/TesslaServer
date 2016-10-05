defmodule TesslaServer.Computation.Filter.IfThenElseTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Filter.IfThenElse
  alias TesslaServer.{Event, GenComputation, Registry}

  import System, only: [unique_integer: 0]

  @cond unique_integer
  @if_signal unique_integer
  @else_signal unique_integer
  @test unique_integer
  @processor unique_integer

  doctest IfThenElse

  setup do
    Registry.register @test
    IfThenElse.start @processor, [@cond, @if_signal, @else_signal]
    :ok
  end

  test "Should compute ITE of two Signal" do

    GenComputation.add_child(@processor, @test)

    timestamp0 = Duration.zero
    timestamp1 = Duration.add timestamp0, Duration.from_seconds 1
    timestamp2 = Duration.add timestamp0, Duration.from_seconds 2
    timestamp3 = Duration.add timestamp0, Duration.from_seconds 3
    timestamp4 = Duration.add timestamp0, Duration.from_seconds 4
    timestamp5 = Duration.add timestamp0, Duration.from_seconds 5
    timestamp6 = Duration.add timestamp0, Duration.from_seconds 6
    timestamp7 = Duration.add timestamp0, Duration.from_seconds 7
    timestamp8 = Duration.add timestamp0, Duration.from_seconds 8

    cond0 = %Event{value: true, stream_id: @cond}
    cond1 = %Event{timestamp: timestamp1, value: false, stream_id: @cond, type: :change}
    cond3 = %Event{timestamp: timestamp3, stream_id: @cond, type: :progress}
    cond4 = %Event{timestamp: timestamp4, value: true, stream_id: @cond, type: :change}
    cond6 = %Event{timestamp: timestamp6, value: false, stream_id: @cond, type: :change}
    cond7 = %Event{timestamp: timestamp7, stream_id: @cond, type: :progress}

    if0 = %Event{value: 1, stream_id: @if_signal, type: :change}
    if2 = %Event{timestamp: timestamp2, value: 2, stream_id: @if_signal, type: :change}
    if4 = %Event{timestamp: timestamp4, value: 4, stream_id: @if_signal, type: :change}
    if6 = %Event{timestamp: timestamp6, value: 6, stream_id: @if_signal, type: :change}
    if7 = %Event{timestamp: timestamp7, stream_id: @if_signal, type: :progress}

    else0 = %Event{value: -1, stream_id: @else_signal, type: :change}
    else2 = %Event{timestamp: timestamp2, value: -2, stream_id: @else_signal, type: :change}
    else3 = %Event{timestamp: timestamp3, value: -3, stream_id: @else_signal, type: :change}
    else5 = %Event{timestamp: timestamp5, value: -5, stream_id: @else_signal, type: :change}
    else6 = %Event{timestamp: timestamp6, value: 4, stream_id: @else_signal, type: :change}
    else8 = %Event{timestamp: timestamp8, stream_id: @else_signal, type: :progress}

    GenComputation.send_event(@processor, cond0)
    GenComputation.send_event(@processor, if0)
    GenComputation.send_event(@processor, else0)
    assert_receive {_, {:process,
      %Event{timestamp: ^timestamp0, value: 1, type: :change}}}

    GenComputation.send_event(@processor, if2)
    GenComputation.send_event(@processor, else2)
    GenComputation.send_event(@processor, cond1)
    assert_receive {_, {:process,
      %Event{type: :change, timestamp: ^timestamp1, value: -1}}}

    GenComputation.send_event(@processor, cond3)
    assert_receive {_, {:process,
      %Event{type: :change, value: -2, timestamp: ^timestamp2}}}

    GenComputation.send_event(@processor, else3)
    GenComputation.send_event(@processor, cond4)

    GenComputation.send_event(@processor, if4)
    assert_receive {_, {:process,
      %Event{type: :change, value: -3, timestamp: ^timestamp3}}}

    GenComputation.send_event(@processor, if6)
    GenComputation.send_event(@processor, else5)
    assert_receive {_, {:process,
      %Event{type: :change, value: 4, timestamp: ^timestamp4}}}

    GenComputation.send_event(@processor, cond6)
    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp5}}}

    GenComputation.send_event(@processor, else6)
    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp6}}}

    GenComputation.send_event(@processor, cond7)
    GenComputation.send_event(@processor, if7)
    GenComputation.send_event(@processor, else8)
    assert_receive {_, {:process,
      %Event{type: :progress, timestamp: ^timestamp7}}}


    :ok = GenComputation.stop @processor
  end
end
