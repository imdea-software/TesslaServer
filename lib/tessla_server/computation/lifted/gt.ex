defmodule TesslaServer.Computation.Lifted.Gt do
  @moduledoc """
  Implements a `Computation` that compares two integer Signals and emits true
  if the first is greater than the second and false otherwise.

  To do so the `state.operands` list has to be initialized with two integers
  representing the ids of the streams that should be the base for the computation.
  The first Stream must be greater than the second to yield `true`.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &>/2, equal_operation: &==/2

  def output_event_type, do: :change
end
