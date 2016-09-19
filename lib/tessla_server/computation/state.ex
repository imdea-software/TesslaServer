defmodule TesslaServer.Computation.State do
  @moduledoc """
  Struct to represent the state of a `Computation`
  """
  alias TesslaServer.GenComputation
  alias TesslaServer.Computation.InputBuffer

  defstruct children: [], input_buffer: nil, stream_id: nil, operands: [],
    options: %{}, output: [], cache: %{}
  @type t :: %__MODULE__{
    stream_id: GenComputation.id,
    input_buffer: InputBuffer.t,
    children: [String.t],
    operands: [GenComputation.id],
    options: %{},
    cache: %{}
  }
end
