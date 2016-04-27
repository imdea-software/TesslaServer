defmodule TesslaServer.Node.History do
  @moduledoc """
  Contains the Structure and Methods to work with the History of a `TesslaServer.Node`
  """

  alias TesslaServer.{Event, Stream}
  alias TesslaServer.Node.History

  defstruct inputs: %{}, output: nil
  @type t :: %__MODULE__{inputs: input_streams, output: Stream.t}
  @typep input_streams :: %{atom => Stream.t}

  @doc """
  Updates the given `history` to prepend the given `event` to the input stream
  specified by the `new_event`

  Returns the new `History`.

  ## Examples

      iex> history = %History{}
      iex> timestamp = Timex.Time.zero
      iex> event = %Event{stream_name: :test, value: :value, timestamp: timestamp}
      iex> updated = History.update_input history, event
      iex> updated.inputs[:test].events |> hd
      %TesslaServer.Event{stream_name: :test, timestamp: {0, 0, 0}, value: :value}
  """
  @spec update_input(History.t, Event.t) :: History.t
  def update_input(history, new_event) do
      stream_to_update = history.inputs[new_event.stream_name]
      {:ok, updated_stream} = Stream.add_event(stream_to_update, new_event)
      put_in(history.inputs[new_event.stream_name], updated_stream)
  end

  @doc """
  Updates the given `history` to prepend the given `new_event` to the output stream

  Returns the new `history`
  """
  @spec update_output(History.t, Event.t) :: History.t
  def update_output(history, new_event) do
    {:ok, updated_output} = Stream.add_event(history.output, new_event)
    %{history | output: updated_output}
  end

  @doc """
  Returns the latest `Event.t` of the input stream specified by `name` in `history`
  """
  @spec get_latest_input_of_stream(History.t, atom) :: Event.t | nil
  def get_latest_input_of_stream(history, name) do
    case get_in(history.inputs, [name]) do
      nil -> nil
      stream -> stream.events |> hd
    end
  end

  @doc """
  Returns the latest `Event.t` that is saved on any input stream
  It assumes that every Stream is ordered by time, meaning it only looks at the head of every Stream
  """
  @spec get_latest_input(History.t) :: Event.t
  def get_latest_input(history) do
    history.inputs
    |> Map.values
    |> Enum.map(&(&1.events))
    |> Enum.map(&(hd &1))
    |> Enum.max_by(&(&1.timestamp))
  end

  @doc """
  Returns the latest `Event` in the output of a History
  """
  @spec get_latest_output(History.t) :: Event.t
  def get_latest_output(history) do
    hd history.output.events
  end
end
