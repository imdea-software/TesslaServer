defmodule TesslaServer.Node.History do
  defstruct inputs: %{}, output: []
  @type t :: %__MODULE__{inputs: input_streams, output: event_stream}
  
  @typep input_streams :: %{atom => event_stream}
  @typep event_stream :: [Event.t]

  @spec update_input(History.t, Event.t) :: History.t
  def update_input(history, new_event) do
    updated_stream = [new_event | history.inputs[new_event.stream_name]]
    put_in(history.inputs[new_event.stream_name], updated_stream)
  end

  @spec update_input(History.t, Event.t) :: History.t
  def update_output(history, new_event) do
    %{history | output: [new_event | history.output]}
  end

  def get_latest_input_of_stream(history, name) do
    case get_in(history.inputs, [name]) do
      nil -> nil
      [] -> nil
      [hd | tl] -> hd
    end
    
  end
end
