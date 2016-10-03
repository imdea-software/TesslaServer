defmodule TesslaServer.Computation.Lifted.Lt do
  @moduledoc """
  Implements a `Computation` that compares two integer Signals and returns true if the first is
  smaller than the second and false otherwise.

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the streams that should be compared.
  The first stream has to be smaller than the second to yield `true`
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &</2, equal_operation: &==/2

  def output_event_type, do: :change
end
