defmodule TesslaServer.Computation.Lifted.Div do
  @moduledoc """
  Implements a `Computation` that divides two Signals.

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the streams which should be the base of the computation.
  The first Stream will be divided by the second.
  This will throw errors when dividing by zero.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &Kernel.//2, equal_operation: &==/2

  def output_event_type, do: :change
end
