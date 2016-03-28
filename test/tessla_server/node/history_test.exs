defmodule TesslaServer.Node.HistoryTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.History
  alias TesslaServer.Event

  doctest History

  test "update_input should return an updated History" do
    timestamp = Time.now
    stream_name = :counter
    event = %Event{timestamp: timestamp, value: 1, stream_name: stream_name}
    history = %History{}

    updated_history = History.update_input(history, event)
    assert(hd(updated_history.inputs[stream_name]) == event)
  end

end
