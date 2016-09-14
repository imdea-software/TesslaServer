defmodule TesslaServer.EventStreamTest do
  use ExUnit.Case, async: true
  use Timex

  import DateTime, only: [shift: 2, to_timestamp: 1]

  alias TesslaServer.{EventStream, Event}

  doctest EventStream

  test "Should update progressed_to with valid timestamp" do
    stream = %EventStream{id: 1}
    timestamp = Time.now

    {:ok, updated_stream} = EventStream.progress(stream, timestamp)

    assert updated_stream.progressed_to == timestamp
  end

  test "Should change nothing when progressing to equal timestamp" do
    stream = %EventStream{id: 1, progressed_to: {3, 4, 5}}

    {:ok, updated_stream} = EventStream.progress(stream, {3, 4, 5})

    assert updated_stream == stream
  end

  test "Shouldn't progress to a timestamp smaller thann current progress"do
    stream = %EventStream{id: 1}
    time = DateTime.now
    timestamp1 = to_timestamp time
    timestamp2 = time |> shift(seconds: -1) |> to_timestamp

    {:ok, updated_stream} = EventStream.progress(stream, timestamp1)
    {:error, _} = EventStream.progress(updated_stream, timestamp2)
  end

  test "Should add valid Event and progress EventStream" do
    stream = %EventStream{id: 1}
    timestamp = Time.now
    event = %Event{timestamp: timestamp, stream_id: 1}

    {:ok, updated_stream} = EventStream.add_event(stream, event)

    assert hd(updated_stream.events) == event
    assert updated_stream.progressed_to == event.timestamp
  end

  test "Should not add Event with wrong stream_id" do
    stream = %EventStream{id: 1}
    timestamp = Time.now
    event = %Event{timestamp: timestamp, stream_id: 2}

    {:error, _} = EventStream.add_event(stream, event)

  end

  test "Should not add Event with timestamp smaller than progressed_to" do
    time = DateTime.now
    timestamp1 = to_timestamp time
    timestamp2 = time |> shift(seconds: -1) |> to_timestamp

    stream = %EventStream{id: 1, progressed_to: timestamp1}
    event = %Event{timestamp: timestamp2, stream_id: 1}

    {:error, _} = EventStream.add_event(stream, event)
  end

  @tag :skip
  test "event_at"
  @tag :skip
  test "events_in_timeslot:"
end
