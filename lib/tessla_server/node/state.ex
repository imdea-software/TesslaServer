defmodule TesslaServer.Node.State do
  defstruct children: [], history: [], options: Keyword.new
  @type t :: %TesslaServer.Node.State{history: [TesslaServer.Event.t], children: [pid], options: Keyword.t}
end
