defmodule TesslaServer.Node.HistoryTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.History
  alias TesslaServer.{EventStream, Event}

  doctest History

  test "processable_events" do
    output_event = %Event{stream_name: :output, timestamp: {2, 0, 0}}
    output = %EventStream{name: :output, progressed_to: {2, 0, 0}, events: [output_event]}

    input1_event1 = %Event{stream_name: :input1, timestamp: {1, 0, 0}}
    input1_event2 = %Event{stream_name: :input1, timestamp: {2, 5, 0}}
    input1_event3 = %Event{stream_name: :input1, timestamp: {3, 0, 0}}
    input1_events = [input1_event3, input1_event2, input1_event1]
    input1 = %EventStream{name: :input1, progressed_to: {3, 0, 0}, events: input1_events}

    input2_event1 = %Event{stream_name: :input2, timestamp: {2, 0, 0}}
    input2_event2 = %Event{stream_name: :input2, timestamp: {3, 0, 0}}
    input2_event3 = %Event{stream_name: :input2, timestamp: {4, 0, 0}}
    input2_events = [input2_event3, input2_event2, input2_event1]
    input2 = %EventStream{name: :input2, progressed_to: {4, 0, 0}, events: input2_events}

    history = %History{inputs: %{input1: input1, input2: input2}, output: output}
    processable_events = History.processable_events history

    expected = [input1_event2, input1_event3, input2_event2]

    assert (processable_events -- expected) == []
    assert (expected -- processable_events ) == []
  end

  test "progress_output works with equal timestamp" do
    history = %History{output: %EventStream{progressed_to: {2, 0, 0}}}
    {:ok, new_history} = History.progress_output history, {2, 0, 0}
    assert new_history.output.progressed_to == {2, 0, 0}
  end
end
