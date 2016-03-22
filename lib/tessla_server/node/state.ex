defmodule TesslaServer.Node.State do
  alias TesslaServer.Node.History

  defstruct children: [], history: %History{}, stream_name: :none, options: %{}
  @type t :: %__MODULE__{stream_name: atom, history: History.t, children: [pid], options: %{}}
end
