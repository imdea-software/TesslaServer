defmodule TesslaServer.Computation.Lifted.Eq do
  @moduledoc """
  Implements a `Computation` that compares two integer Signals.
  if both are the same and false otherwise

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the streams that should be the base of the computation.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &==/2, equal_operation: &==/2

  def output_event_type, do: :change
end
