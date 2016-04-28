defmodule TesslaServer.Node.History do
  @moduledoc """
  Contains the Structure and Methods to work with the History of a `TesslaServer.Node`
  """

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.History

  defstruct inputs: %{}, output: nil
  @type t :: %__MODULE__{inputs: input_streams, output: EventStream.t}
  @typep input_streams :: %{atom => EventStream.t}

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
      {:ok, updated_stream} = EventStream.add_event(stream_to_update, new_event)
      put_in(history.inputs[new_event.stream_name], updated_stream)
  end

  @doc """
  Replaces the input `EventStream` with the same name as `stream` of the `history`.
  If the history doesn't include a `EventStream` with the name an error will be returned.

  ## Examples

      iex> stream = %EventStream{name: :test, progressed_to: {1, 2, 3}}
      iex> history = %History{inputs: %{test: stream}}
      iex> new_stream = %EventStream{name: :test, progressed_to: {2, 3, 4}}
      iex> History.replace_input_stream(history, new_stream)
      {:ok, %History{inputs: %{test: %EventStream{name: :test, progressed_to: {2, 3, 4}}}}}

      iex> stream = %EventStream{name: :test}
      iex> history = %History{inputs: %{test: stream}}
      iex> new_stream = %EventStream{name: :wrong_name}
      iex> History.replace_input_stream(history, new_stream)
      {:error, "No EventStream with that name in inputs of History"}
  """
  @spec replace_input_stream(History.t, EventStream.t) :: {:ok, History.t} | {:error, String.t}
  def replace_input_stream(history, stream) do
    inputs = history.inputs
    if Map.has_key?(inputs, stream.name) do
      updated_inputs = Map.put(inputs, stream.name, stream)
      {:ok, %{history | inputs: updated_inputs}}
    else
      {:error, "No EventStream with that name in inputs of History"}
    end
  end

  @doc """
  Updates the given `history` to prepend the given `new_event` to the output stream

  Returns the new `history`
  """
  @spec update_output(History.t, Event.t) :: History.t
  def update_output(history, new_event) do
    {:ok, updated_output} = EventStream.add_event(history.output, new_event)
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
  It assumes that every EventStream is ordered by time, meaning it only looks at the head of every EventStream
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
