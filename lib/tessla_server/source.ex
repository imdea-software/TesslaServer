defmodule TesslaServer.Source do
  @moduledoc """
  Represents a Stream Source
  """

  alias TesslaServer.Event
  defstruct children: [], events: [], name: nil
  @type t :: %__MODULE__{name: atom, events: [Event.t], children: [pid]}

  use GenServer

  def init(args) do
    {:ok, %__MODULE__{children: args[:children], name: args[:name]}}
  end

  def handle_cast({:new_event, event}, state) do
    processed_event = %{ event | stream_name: state.name }
    new_state = %{state | events: [processed_event | state.events]}
    Enum.each(state.children, &GenServer.cast(&1, {:process, processed_event} ))
    { :noreply, new_state }
  end

  @spec handle_cast({:add_child, pid}, State.t) :: { :noreply, State.t }
  def handle_cast({:noreply, new_child}, state) do
    %{ state | children: [new_child | state.children]}
  end


end
