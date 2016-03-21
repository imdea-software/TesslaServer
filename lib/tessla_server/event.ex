defmodule TesslaServer.Event do
  use Timex
  defstruct timestamp: Time.now, description: :nothing
  @type t :: %TesslaServer.Event{timestamp: Timex.Tipes.timestamp, description: any}
end
