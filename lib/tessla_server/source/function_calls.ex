defmodule TesslaServer.Source.FunctionCalls do
  @moduledoc """
  Implements a `Source` that emits Events whenever the specified Function is called.
  The Function specifier has to be in the `option` key `argument`

  """

  alias TesslaServer.Node

  use Node

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.State

  def init(state) do
    :gproc.reg({:p, :l, hd(state.options[:argument])})
    super state
  end

  def perform_computation(timestamp, event_map, state) do
    processed_event = %Event{timestamp: timestamp, stream_id: state.stream_id}
    {:ok, processed_event}
  end
end
