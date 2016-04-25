defmodule TesslaServer.StreamTest do
  use ExUnit.Case, async: true
  use Timex

  alias TesslaServer.{Stream, Event}

  doctest Stream

  test "Should update progressed_to" do
    refute "Not Implementend"
  end

  test "Should add valid Event and progress Stream" do
    refute "Not Implementend"
  end

  test "Should not add Event with timestamp smaller than progressed_to" do
    refute "Not implemented"
  end
end
