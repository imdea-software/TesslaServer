defmodule TesslaServer.Event do
  @moduledoc """
  Represents an `Event` on a Stream.
  Note that Event here is meant in a broader sense than the Tessla one,
  as it can represent an event on an eventstream, a change of a signal or
  the progress of a stream.
  """

  alias TesslaServer.GenComputation

  defstruct timestamp: ~T[00:00:00.001], stream_id: nil, value: :nothing, type: :event
  @type t :: %__MODULE__{timestamp: Time.t | :literal, value: any,
   stream_id: GenComputation.id, type: event_type}
  @type event_type :: :event | :change | :progress
end
