defmodule TesslaServer.Computation.Lifted.Implies do
  @moduledoc """
  Implements a `Computation` that performs an `implies` on two boolean Signals.

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the streams that should be the base of the computation.
  The first stream will be used as the left side of the implies formula.
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &implies/2, equal_operation: &==/2

  def output_event_type, do: :change

  def implies(value1, value2) do
    !value1 or value2
  end
end
