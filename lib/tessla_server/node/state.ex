defmodule TesslaServer.Node.State do
  @moduledoc """
  Struct to represent the state of a `Node`
  """
  alias TesslaServer.Node.History

  defstruct children: [], history: %History{}, stream_id: nil, operands: [], options: %{}
  @type t :: %__MODULE__{stream_id: integer | nil, history: History.t, children: [String.t],
   operands: [atom], options: %{}}
end
