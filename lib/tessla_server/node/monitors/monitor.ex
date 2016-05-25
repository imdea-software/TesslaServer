defmodule TesslaServer.Node.Monitors.Monitor do
  @moduledoc """
  Implements an Monitor based on multiple inputs, that are used in the LTL expression and a clock.
  state.options has to hold the id of the clock, the states and the transitions.
  """

  alias TesslaServer.SimpleNode

  use SimpleNode
  def perform_computation(timestamp, event_map, state) do
    IO.puts inspect event_map,
    IO.puts inspect state
    :wait
  end

  def output_stream_type, do: :events
end
