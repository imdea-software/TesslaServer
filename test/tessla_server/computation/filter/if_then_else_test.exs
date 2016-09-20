defmodule TesslaServer.Computation.Filter.IfThenElseTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Computation.Filter.IfThenElse
  alias TesslaServer.{Event, GenComputation, Registry}

  import DateTime, only: [now: 0, shift: 2, to_timestamp: 1]
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
    assert_receive({_, {:update_input_stream, initial_output}})
    assert(initial_output.progressed_to == Time.zero)
    assert(initial_output.events == [])
    assert initial_output.type == :signal

    timestamp = DateTime.now

    cond1 = %Event{value: true, stream_id: @cond}
    cond2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 1)), value: false, stream_id: @cond}
    cond3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: true, stream_id: @cond}
    cond4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 7)), value: false, stream_id: @cond}

    if1 = %Event{value: 1, stream_id: @if_signal}
    if2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: 2, stream_id: @if_signal}
    if3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: 3, stream_id: @if_signal}
    if4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 5)), value: 4, stream_id: @if_signal}
    if5 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 6)), value: 5, stream_id: @if_signal}
    if6 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 7)), value: 6, stream_id: @if_signal}

    else1 = %Event{value: -1, stream_id: @else_signal}
    else2 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 2)), value: -2, stream_id: @else_signal}
    else3 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 4)), value: -3, stream_id: @else_signal}
    else4 = %Event{timestamp: to_timestamp(shift(timestamp, seconds: 7)), value: -4, stream_id: @else_signal}

    GenComputation.send_event(@processor, cond1)
    refute_receive(_)

    GenComputation.send_event(@processor, if1)
    refute_receive(_)

    GenComputation.send_event(@processor, else1)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out1]}}})
    assert(progressed_to == cond1.timestamp)
    assert(out1.value == if1.value)

    GenComputation.send_event(@processor, if2)
    refute_receive(_)
    GenComputation.send_event(@processor, if3)
    refute_receive(_)
    GenComputation.send_event(@processor, else2)
    refute_receive(_)
    GenComputation.send_event(@processor, else3)
    refute_receive(_)

    GenComputation.send_event(@processor, cond2)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to, events: [out2, ^out1]}}})
    assert progressed_to == cond2.timestamp
    assert out2.value == else1.value

    GenComputation.send_event(@processor, cond3)
    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to,
        events: [out4, out3, ^out2, ^out1]}}}
    )
    assert progressed_to == cond3.timestamp
    assert out3.value == else2.value
    assert out3.timestamp == else2.timestamp
    assert out4.value == if3.value
    assert out4.timestamp == cond3.timestamp

    GenComputation.send_event(@processor, cond4)
    refute_receive _

    GenComputation.send_event(@processor, if4)
    refute_receive _
    GenComputation.send_event(@processor, if5)
    refute_receive _
    GenComputation.send_event(@processor, if6)
    refute_receive _
    GenComputation.send_event(@processor, else4)

    assert_receive({_, {:update_input_stream, %{progressed_to: progressed_to,
        events: [out7, out6, out5, ^out4, ^out3, ^out2, ^out1]}}}
    )
    assert progressed_to == cond4.timestamp
    assert out5.value == if4.value
    assert out5.timestamp == if4.timestamp
    assert out6.value == if5.value
    assert out6.timestamp == if5.timestamp
    assert out7.value == else4.value
    assert out7.timestamp == else4.timestamp

    :ok = GenComputation.stop @processor
  end
end
