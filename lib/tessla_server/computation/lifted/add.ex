defmodule TesslaServer.Computation.Lifted.Add do
  @moduledoc """
  Implements a `Computation` that adds two Signals.

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the two streams that are the base of the computation.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &+/2, equal_operation: &==/2

  def output_event_type, do: :change
end
