defmodule TesslaServer.Node.SpecProcessor.MinimalTest do
  use ExUnit.Case, async: true

  alias TesslaServer.{Node, SpecProcessor, Event, Source}

  import TesslaServer.Registry

  test "Should Setup the minimal testcase and process Events" do
    {:ok, spec} = File.read("test/examples/minimal.tessla")
    SpecProcessor.process spec
    :timer.sleep 1000

    :gproc.reg(gproc_tuple(:minimal_test))
    Node.add_child(:error, :minimal_test)
    function_call_channel = :"function_call:minimal.c:test"
    variable_update_channel = :"variable_update:minimal.c:x"

    assert_receive({_, {:update_input_stream, new_stream}})
    assert new_stream.name == :error
    assert new_stream.progressed_to == {0, 0, 0}
    assert new_stream.events == []

    timestamp1 = {1, 0, 0}

    variable_update_1 = %Event{stream_name: variable_update_channel, value: ["1"], timestamp: timestamp1}

    Source.distribute(variable_update_1)
    refute_receive update

    function_call_1 = %Event{stream_name: function_call_channel, value: ["1"], timestamp: timestamp1}

    Source.distribute(function_call_1)

    assert_receive {_, {:update_input_stream, new_stream}}
    [first_output] = new_stream.events
    assert first_output.value
    assert new_stream.progressed_to == timestamp1
    assert new_stream.name == :error

    timestamp2 = {2, 0, 0}
    function_call_2 = %Event{stream_name: function_call_channel, value: ["0"], timestamp: timestamp2}

    Source.distribute(function_call_2)

    refute_receive update

    timestamp3 = {3, 0, 0}
    function_call_3 = %Event{stream_name: function_call_channel, value: ["2"], timestamp: timestamp3}

    Source.distribute(function_call_3)

    refute_receive update

    timestamp4 = {4, 0, 0}
    function_call_4 = %Event{stream_name: function_call_channel, value: ["3"], timestamp: timestamp4}

    Source.distribute(function_call_4)

    refute_receive update

    variable_update_2 = %Event{stream_name: variable_update_channel, value: ["2"], timestamp: timestamp3}

    Source.distribute(variable_update_2)

    assert_receive({_, {:update_input_stream, new_stream}})

    [output3, output2, output1] = new_stream.events

    assert output1 == first_output
    refute output2.value
    assert output3.value
    assert new_stream.progressed_to == timestamp3

    :ok = Node.stop :test_calls
    :ok = Node.stop :x_values
    :ok = Node.stop :error
  end
end
