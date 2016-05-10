defmodule TesslaServer.Source.InstructionExecutions do
  @moduledoc """
  Implements a `Source` that emits events without a value whenever a specified instruction is
  executed.
  The instruction has to be specified as a `String.t` in `options` under the key `instruction`.
  """

  alias TesslaServer.Node

  use Node

  alias TesslaServer.Event

  def init(state) do
    channel = "instruction_executions:" <> state.options[:instruction]
    :gproc.reg({:p, :l, channel})
    super state
  end

  def perform_computation(timestamp, _, state) do
    processed_event = %Event{timestamp: timestamp,  stream_id: state.stream_id}
    {:ok, processed_event}
  end
end
