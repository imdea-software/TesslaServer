defmodule TesslaServer.Event do
  @moduledoc """
  Contains the struct to represents Events which are modified by `TesslaServer.Node` implementations
  """
  use Timex
  defstruct timestamp: Time.now, stream_name: :none, value: :nothing
  @type t :: %__MODULE__{timestamp: Timex.Types.timestamp, value: any, stream_name: atom}
end
