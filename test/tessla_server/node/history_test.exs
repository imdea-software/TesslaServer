defmodule TesslaServer.Node.HistoryTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.Node.History
  alias TesslaServer.{EventStream, Event}

  doctest History

  test "processable_events", do: flunk
  test "replace_input_stream", do: flunk
  test "update_output", do: flunk
  test " get_latest_input_of_stream", do: flunk
  test " get_latest_input", do: flunk
  test " get_latest_output", do: flunk
end
