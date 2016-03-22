defmodule TesslaServer.Node.History do
  @moduledoc """
  Contains the Structure and Methods to work with the History of a `TesslaServer.Node`
  """

  alias TesslaServer.Event
  alias TesslaServer.Node.History

  defstruct inputs: %{}, output: []
  @type t :: %__MODULE__{inputs: input_streams, output: event_stream}
  
  @typep input_streams :: %{atom => event_stream}
  @typep event_stream :: [Event.t]

  @doc """
  Updates the given `history` to prepend the given `event` to the input stream specified by the `new_event`

  Returns the new `History`
  """
  @spec update_input(History.t, Event.t) :: History.t
  def update_input(history, new_event) do
    updated_stream = [new_event | history.inputs[new_event.stream_name]]
    put_in(history.inputs[new_event.stream_name], updated_stream)
  end

  @doc """
  Updates the given `history` to prepend the given `new_event` to the output stream

  Returns the new `history`
  """
  @spec update_output(History.t, Event.t) :: History.t
  def update_output(history, new_event) do
    %{history | output: [new_event | history.output]}
  end

  @doc """
  Returns the latest `Event.t` of the input stream specified by `name` in `history`
  """
  @spec get_latest_input_of_stream(History.t, atom) :: Event.t | nil
  def get_latest_input_of_stream(history, name) do
    case get_in(history.inputs, [name]) do
      nil -> nil
      [] -> nil
      [hd | _] -> hd
    end
    
  end
end
