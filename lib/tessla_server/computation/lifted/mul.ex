defmodule TesslaServer.Computation.Lifted.Mul do
  @moduledoc """
  Implements a `Computation` that multiplies two Signals.

  To do so the `state.operands` list has to be initialized with two integers representing the ids of
  the event streams that should be multiplied.
  """
  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &*/2, equal_operation: &==/2

  def output_event_type, do: :change
end
