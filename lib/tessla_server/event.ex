defmodule TesslaServer.Event do
  use Timex
  defstruct timestamp: Time.now, stream_name: :none, value: :nothing
  @type t :: %__MODULE__{timestamp: Timex.Tipes.timestamp, value: any, stream_name: atom}
end
