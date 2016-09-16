defmodule TesslaServer.Computation.State do
  @moduledoc """
  Struct to represent the state of a `Computation`
  """
  alias TesslaServer.GenComputation

  defstruct children: [], inputs: %{}, stream_id: nil, operands: [], options: %{}, output: []
  @type t :: %__MODULE__{
    stream_id: integer | nil, inputs: GenComputation.input_queue,
    children: [String.t], operands: [integer], options: %{}, output: [Event.t]
  }
end
