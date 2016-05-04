defmodule TesslaServer.Node.History do
  @moduledoc """
  Contains the Structure and Methods to work with the History of a `TesslaServer.Node`
  """

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.History

  defstruct inputs: %{}, output: nil
  @type t :: %__MODULE__{inputs: input_streams, output: EventStream.t}
  @typep input_streams :: %{atom => EventStream.t}
  @type timestamp :: Timex.Types.timestamp

  @doc """
  Returns all events on all inputs with a `timestamp` between `progressed_to` of the output and
  the minimum of the `progressed_to` of all inputs.
  """
  @spec processable_events(History.t) :: [Event.t]
  def processable_events(history) do
    upto =
      history.inputs
      |> Map.values
      |> Enum.map(&(&1.progressed_to))
      |> Enum.min
    from = history.output.progressed_to
    events =
      Enum.flat_map history.inputs, fn {name, stream} ->
        EventStream.events_in_timeslot(stream, from, upto)
      end
  end

  @doc """
  Replaces the input `EventStream` with the same name as `stream` of the `history`.
  If the history doesn't include an `EventStream` with the name an error will be returned.

  ## Examples

      iex> stream = %EventStream{name: :test, progressed_to: {1, 2, 3}}
      iex> history = %History{inputs: %{test: stream}}
      iex> new_stream = %EventStream{name: :test, progressed_to: {2, 3, 4}}
      iex> History.replace_input_stream(history, new_stream)
      {:ok, %History{inputs: %{test: %EventStream{name: :test, progressed_to: {2, 3, 4}}}}}

      iex> history = %History{}
      iex> new_stream = %EventStream{name: :test, progressed_to: {2, 3, 4}}
      iex> History.replace_input_stream(history, new_stream)
      {:ok, %History{inputs: %{test: %EventStream{name: :test, progressed_to: {2, 3, 4}}}}}
  """
  @spec replace_input_stream(History.t, EventStream.t) :: {:ok, History.t}
  def replace_input_stream(history, stream) do
    inputs = history.inputs
    updated_inputs = Map.put(inputs, stream.name, stream)
    {:ok, %{history | inputs: updated_inputs}}
  end

  @doc """
  Updates the given `history` to prepend the given `new_event` to the output stream.
  The `event` has to have the same `stream_name` than the `name` of the `output`, else an
  error will be returned.
  Also the `timestamp` of the `event` has to be bigger than the `progressed_to` of the `output`,
  else an error will be returned.
  The `progressed_to` of the `output` will be set to the `timestamp` of the `event`
  Returns the new `history` if no errors occur.

  ## Examples

      iex> output = %EventStream{name: :output, progressed_to: {0, 2, 3}}
      iex> history = %History{output: output}
      iex> new_event = %Event{stream_name: :output, timestamp: {1, 0, 0}}
      iex> History.update_output(history, new_event)
      {:ok,
        %History{
          output: %EventStream{
            name: :output,
            progressed_to: {1, 0, 0},
            events: [%Event{stream_name: :output, timestamp: {1, 0, 0}}]
          }
        }
      }

      iex> output = %EventStream{name: :output, progressed_to: {1, 2, 3}}
      iex> history = %History{output: output}
      iex> new_event = %Event{stream_name: :output, timestamp: {1, 0, 0}}
      iex> History.update_output(history, new_event)
      {:error, "Event's timestamp smaller than stream progress"}

      iex> output = %EventStream{name: :output, progressed_to: {0, 2, 3}}
      iex> history = %History{output: output}
      iex> new_event = %Event{stream_name: :wrong, timestamp: {1, 0, 0}}
      iex> History.update_output(history, new_event)
      {:error, "Event has different stream_name than stream"}
  """
  @spec update_output(History.t, Event.t) :: {:ok, History.t} | {:error, String.t}
  def update_output(history, new_event) do
    case  EventStream.add_event(history.output, new_event) do
      {:ok, updated_output} -> {:ok, %{history | output: updated_output}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Sets the `progressed_to` of the `output` of the `history` to the `timestamp`
  """
  @spec progress_output(History.t, timestamp) :: History
  def progress_output(history, timestamp) do
    case EventStream.progress(history.output, timestamp) do
      {:ok, updated_output} ->
        %{history | output: updated_output}
      {:error, reason} ->
        raise "Couldn't update timestamp of output"
    end
  end

  @doc """
  Returns the latest `Event.t` of the input stream specified by `name` in `history`
  that has a `timestamp` smaller than `at`
  """
  @spec latest_event_of_input_at(History.t, atom, timestamp) :: Event.t | nil
  def latest_event_of_input_at(history, name, timestamp) do
    case get_in(history.inputs, [name]) do
      nil -> nil
      stream ->
        EventStream.event_at(stream, timestamp)
    end
  end

  @doc """
  Returns the latest `Event.t` that is saved on any input stream
  """
  @spec latest_input_event_at(History.t, timestamp) :: Event.t | nil
  def latest_input_event_at(history, timestamp) do
    history.inputs
    |> Map.values
    |> Enum.map(&EventStream.event_at(&1, timestamp))
    |> Enum.max_by(&(&1.timestamp))
  end

  @doc """
  Returns the latest `Event` in the output of a History
  """
  @spec latest_output(History.t) :: Event.t
  def latest_output(history) do
    hd history.output.events
  end
end
