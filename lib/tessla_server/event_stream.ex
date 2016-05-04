defmodule TesslaServer.EventStream do
  @moduledoc """
  Represents a Stream, generated either from external Events or by computation through
  a `Node`
  Note that `progressed_to` can be bigger than the `timestamp` of the latest `Event`:
  If all Inputs of the `Node` generating this `Stream` have advanced to at least `t` but
  no new Event is generated (e.g. because the `Node` is a delay with a higher value)
  the `Stream` will be progressed to `t` but no Event with a timestamp `t` is present.
  """
  use Timex
  alias TesslaServer.Event

  @type t :: %__MODULE__{progressed_to: Timex.Types.timestamp, name: atom, events: [Event.t]}
  defstruct progressed_to: Time.zero, name: :none, events: []

  @type timestamp :: Timex.Types.timestamp

  @doc """
  Progresses the `EventStream` to the given `timestamp`.

      iex> timestamp = {1234, 123456, 123456}
      iex> stream = %EventStream{}
      iex> EventStream.progress(stream, timestamp)
      {:ok, %EventStream{progressed_to: {1234, 123456, 123456}}}

  The `timestamp` has to be bigger than the `stream`s `progressed_to`
  or else an error will be returned.

      iex> timestamp = {1, 0, 0}
      iex> stream = %EventStream{progressed_to: {2, 0, 0}}
      iex> EventStream.progress(stream, timestamp)
      {:error, "Timestamp smaller than progress of EventStream"}
  """
  @spec progress(EventStream.t, timestamp) :: {:ok, EventStream.t} | {:error, String.t}
  def progress(%{progressed_to: progressed_to}, timestamp)
  when progressed_to > timestamp, do: {:error, "Timestamp smaller than progress of EventStream"}
  def progress(stream, timestamp) when is_tuple(timestamp) do
    {:ok, %{stream | progressed_to: timestamp}}
  end

  @doc """
  Adds the `Event` to the `EventStream`.

      iex> event = %Event{stream_name: :test, timestamp: {1000, 123456, 123456}, value: 1}
      iex> stream = %EventStream{name: :test}
      iex> {:ok, updated_stream} = EventStream.add_event(stream, event)
      iex> hd(updated_stream.events)
      %TesslaServer.Event{stream_name: :test, timestamp: {1000, 123456, 123456}, value: 1}

  If the stream is nil it will create a new `EventStream` with the name of the `event` and
  `progressed_to` equal to the `timestamp` of the `event`

      iex> event = %Event{stream_name: :test, timestamp: {1000, 123456, 123456}, value: 1}
      iex> stream = nil
      iex> {:ok, updated_stream} = EventStream.add_event(stream, event)
      iex> updated_stream
      %TesslaServer.EventStream{
        events: [%TesslaServer.Event{stream_name: :test, timestamp: {1000, 123456, 123456}, value: 1}],
        name: :test,
        progressed_to: {1000, 123456, 123456}
      }

  The `timestamp` of the `Event` has to be greater or equal to the `progressed_to` value
  of the `EventStream`.

      iex> event = %Event{stream_name: :test, timestamp: {0, 1, 2}, value: 1}
      iex> stream = %EventStream{name: :test, progressed_to: {1, 2, 3}}
      iex> {:error, reason} = EventStream.add_event(stream, event)
      iex> reason
      "Event's timestamp smaller than stream progress"

  The `stream_name` of the `Event` has to be the same as the `name` of the EventStream or else an
  error will be returned.

      iex> event = %Event{stream_name: :wrong_name, timestamp: {1000, 123456, 123456}, value: 1}
      iex> stream = %EventStream{name: :test}
      iex> {:error, reason} = EventStream.add_event(stream, event)
      iex> reason
      "Event has different stream_name than stream"


  This method will advance the `progressed_to` field to the `timestamp` of the `Event`.
  """
  @spec add_event(nil | EventStream.t, Event.t) ::  {:ok, EventStream.t} | {:error, String.t}
  def add_event(nil, event) do
    {:ok, %__MODULE__{name: event.stream_name, progressed_to: event.timestamp, events: [event]}}
  end
  def add_event(%{name: name}, %{stream_name: stream_name})
  when name != stream_name, do: {:error, "Event has different stream_name than stream"}
  def add_event(%{progressed_to: progressed_to}, %{timestamp: timestamp})
  when progressed_to > timestamp, do: {:error, "Event's timestamp smaller than stream progress"}
  def add_event(stream, event) do
    {:ok, %{stream | events: [event | stream.events], progressed_to: event.timestamp}}
  end

  @doc """
  Returns all event on the stream with a `timestamp` bigger than `from` and smaller or equal to
  `to`.
  To work, the stream has to be ordered by it's `timestamps`, which all `Stream.t` structs should
  be always.

  ##Examples

      iex> event0 = %Event{timestamp: {0, 0, 0}, stream_name: :test, value: 0}
      iex> event1 = %Event{timestamp: {1, 0, 0}, stream_name: :test, value: 1}
      iex> event2 = %Event{timestamp: {2, 0, 0}, stream_name: :test, value: 2}
      iex> event3 = %Event{timestamp: {3, 0, 0}, stream_name: :test, value: 3}
      iex> event4 = %Event{timestamp: {4, 0, 0}, stream_name: :test, value: 4}
      iex> events = [event4, event3, event2, event1, event0]
      iex> stream = %EventStream{name: :test, progressed_to: {4, 0, 0}, events: events}
      iex> EventStream.events_in_timeslot(stream, {1, 0, 0}, {3,0,0})
      [%Event{timestamp: {3, 0, 0}, stream_name: :test, value: 3},
      %Event{timestamp: {2, 0, 0}, stream_name: :test, value: 2}]

  """
  @spec events_in_timeslot(EventStream.t | nil, timestamp, timestamp) :: [Event.t]
  def events_in_timeslot(nil, _, _), do: []
  def events_in_timeslot(stream, from, to) do
    stream.events
    |> Enum.drop_while(&(&1.timestamp > to))
    |> Enum.take_while(&(&1.timestamp > from))
  end

  @doc """
  Returns the most recent `Event.t` that occured at or before `at`

  ## Examples

      iex> event0 = %Event{stream_name: :test, value: 0, timestamp: {0, 0, 0}}
      iex> event1 = %Event{stream_name: :test, value: 1, timestamp: {1, 0, 0}}
      iex> event2 = %Event{stream_name: :test, value: 2, timestamp: {2, 0, 0}}
      iex> events = [event2, event1, event0]
      iex> stream = %EventStream{name: :test, progressed_to: {2, 0, 0}, events: events}
      iex> EventStream.event_at(stream, {1, 0, 0})
      %Event{stream_name: :test, value: 1, timestamp: {1, 0, 0}}

      iex> event2 = %Event{stream_name: :test, value: 2, timestamp: {2, 0, 0}}
      iex> events = [event2]
      iex> stream = %EventStream{name: :test, progressed_to: {2, 0, 0}, events: events}
      iex> EventStream.event_at(stream, {1, 0, 0})
      nil
  """
  @spec event_at(EventStream.t, timestamp) :: Event.t | nil
  def event_at(stream, at) do
    stream.events
    |> Enum.drop_while(&(&1.timestamp > at))
    |> Enum.at(0)
  end
end
