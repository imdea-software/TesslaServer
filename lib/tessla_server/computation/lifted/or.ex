defmodule TesslaServer.Computation.Lifted.Or do
  @moduledoc """
  Implements a `Computation` that performs an `or` on two boolean streams

  To do so the `state.operands` list has to be initialized with two integers representing the ids
  of the streams which should be the base of the computation
  """

  alias TesslaServer.{GenComputation, Event}
  alias TesslaServer.Computation.State
  alias TesslaServer.Computation.Lifted.GenLifted

  use GenComputation
  use GenLifted, combine_operation: &or/2, equal_operation: &==/2

  def output_event_type, do: :change
end
