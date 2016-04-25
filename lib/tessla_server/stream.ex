defmodule TesslaServer.Stream do
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

  @type t :: %__MODULE__{progressed_to: Timex.Types.timestamp, stream_name: atom, events: [Event.t]}
  defstruct progressed_to: Time.zero, stream_name: :none, events: []

  @doc """
  Progresses the `Stream` to the given `timestamp`
  """
  @spec progress(Stream.t, Timex.Types.timestamp) :: Stream.t
  def progress(stream, timestamp) do
    %{stream | progressed_to: timestamp}
  end

  @doc """
  Adds the `Event` to the `Stream`.
  The `timestamp` of the `Event` has to be greater or equal to to `progressed_to` value
  of the `Stream`.
  This method will advance the `progressed_to` field to the `timestamp` of the `Event`.
  """
  @spec add_event(Stream.t, Event.t) :: Stream.t
  def add_event(stream, event) do
    %{stream |
     events: [event | stream.events],
     progressed_to: event.timestamp
   }
  end
end
