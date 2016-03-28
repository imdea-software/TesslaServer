defmodule TesslaServer.Source do
  @moduledoc """
  Represents a Stream Source
  """
  
  alias TesslaServer.Event
  defstruct subscribers: [], events: [], name: nil
  @type t :: %__MODULE__{name: atom, events: [Event.t], subscribers: [pid]}

  use GenServer

  def init(args) do
    {:ok, %__MODULE__{subscribers: args[:subscribers], name: args[:name]}}
  end
  
  def handle_cast({:new_event, event}, state) do
    processed_event = %{ event | stream_name: state.name }
    new_state = %{state | events: [processed_event | state.events]}
    Enum.each(state.subscribers, &GenServer.cast(&1, {:process, processed_event} ))
    { :noreply, new_state }
  end
end
