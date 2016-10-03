defmodule TesslaServer.Computation.Lifted.Max do
  @moduledoc """
  Implements a `Computation` that compares two integer signals and yields the value of the bigger one.

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the streams that should be compared
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &max/2, equal_operation: &==/2

  def output_event_type, do: :change
end
