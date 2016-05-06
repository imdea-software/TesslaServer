defmodule TesslaServer.Node.History do
  @moduledoc """
  Contains the Structure and Methods to work with the History of a `TesslaServer.Node`
  """

  alias TesslaServer.{Event, EventStream}
  alias TesslaServer.Node.History

  defstruct inputs: %{}, output: nil
  @type t :: %__MODULE__{inputs: input_streams, output: EventStream.t}
  @typep input_streams :: %{integer => EventStream.t}
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
      Enum.flat_map history.inputs, fn {id, stream} ->
        EventStream.events_in_timeslot(stream, from, upto)
      end
  end

  @doc """
  Replaces the `input_stream` of the `history` with the same `id` as the new `stream` with
  the new stream.
  If the `inputs` of the `history` don't include an `EventStream` with the `id` the new `stream`
  will be added to the `history`

  ## Examples

      iex> stream = %EventStream{id: 1, progressed_to: {1, 2, 3}}
      iex> history = %History{inputs: %{1 => stream}}
      iex> new_stream = %EventStream{id: 1, progressed_to: {2, 3, 4}}
      iex> History.replace_input_stream(history, new_stream)
      {:ok, %History{inputs: %{1 => %EventStream{id: 1, progressed_to: {2, 3, 4}}}}}

      iex> history = %History{}
      iex> new_stream = %EventStream{id: 1, progressed_to: {2, 3, 4}}
      iex> History.replace_input_stream(history, new_stream)
      {:ok, %History{inputs: %{1 => %EventStream{id: 1, progressed_to: {2, 3, 4}}}}}
  """
  @spec replace_input_stream(History.t, EventStream.t) :: {:ok, History.t}
  def replace_input_stream(history, stream) do
    inputs = history.inputs
    updated_inputs = Map.put(inputs, stream.id, stream)
    {:ok, %{history | inputs: updated_inputs}}
  end

  @doc """
  Updates the given `history` to prepend the given `new_event` to the output stream.
  The `event` has to have the same `stream_id` than the `id` of the `output`, else an
  error will be returned.
  Also the `timestamp` of the `event` has to be bigger than the `progressed_to` of the `output`,
  else an error will be returned.
  The `progressed_to` of the `output` will be set to the `timestamp` of the `event`
  Returns the new `history` if no errors occur.

  ## Examples

      iex> output = %EventStream{id: 1, progressed_to: {0, 2, 3}}
      iex> history = %History{output: output}
      iex> new_event = %Event{stream_id: 1, timestamp: {1, 0, 0}}
      iex> History.update_output(history, new_event)
      {:ok,
        %History{
          output: %EventStream{
            id: 1,
            progressed_to: {1, 0, 0},
            events: [%Event{stream_id: 1, timestamp: {1, 0, 0}}]
          }
        }
      }

      iex> output = %EventStream{id: 1, progressed_to: {1, 2, 3}}
      iex> history = %History{output: output}
      iex> new_event = %Event{stream_id: 1, timestamp: {1, 0, 0}}
      iex> History.update_output(history, new_event)
      {:error, "Event's timestamp smaller than stream progress"}

      iex> output = %EventStream{id: 1, progressed_to: {0, 2, 3}}
      iex> history = %History{output: output}
      iex> new_event = %Event{stream_id: 2, timestamp: {1, 0, 0}}
      iex> History.update_output(history, new_event)
      {:error, "Event has different stream_id than stream"}
  """
  @spec update_output(History.t, Event.t) :: {:ok, History.t} | {:error, String.t}
  def update_output(history, new_event) do
    case  EventStream.add_event(history.output, new_event) do
      {:ok, updated_output} -> {:ok, %{history | output: updated_output}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Sets the `progressed_to` of the `output` of the `history` to the `timestamp`.
  The `timestamp` has to be greater or equal than the `progressed_to` of the `output` of the `history`
  or an `:error` will be returned.

  ## Examples

      iex> history = %History{output: %EventStream{progressed_to: {3, 0, 0}}}
      iex> History.progress_output history, {4, 0, 0}
      {:ok, %History{output: %EventStream{progressed_to: {4, 0, 0}}}}

      iex> history = %History{output: %EventStream{progressed_to: {3, 0, 0}}}
      iex> History.progress_output history, {2, 0, 0}
      {:error, "Timestamp smaller than progress of EventStream"}
  """
  @spec progress_output(History.t, timestamp) :: {:ok, History.t} | {:error, String.t}
  def progress_output(history, timestamp) do
    case EventStream.progress(history.output, timestamp) do
      {:ok, updated_output} -> {:ok, %{history | output: updated_output}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the latest `Event.t` of the input stream specified by `id` in `history`
  that has a `timestamp` smaller than `at`.

  If the `history` has no input with the `id` or the input has no `Event` that happened before
  the `timestamp` `nil` is returned.

  ## Examples

      iex> event1 = %Event{stream_id: 1, timestamp: {2, 0, 0}}
      iex> event2 = %Event{stream_id: 1, timestamp: {3, 0, 0}}
      iex> event3 = %Event{stream_id: 1, timestamp: {4, 0, 0}}
      iex> events = [event3, event2, event1]
      iex> input1 = %EventStream{id: 1, events: events, progressed_to: {4, 0, 0}}
      iex> history = %History{inputs: %{1 => input1}}
      iex> History.latest_event_of_input_at(history, 1, {1, 0, 0})
      nil
      iex> History.latest_event_of_input_at(history, 1, {3, 0, 0})
      %Event{stream_id: 1, timestamp: {3, 0, 0}}
      iex> History.latest_event_of_input_at(history, 1, {2, 5, 0})
      %Event{stream_id: 1, timestamp: {2, 0, 0}}

      iex> history = %History{}
      iex> History.latest_event_of_input_at(history, :any, {1, 0, 0})
      nil
  """
  @spec latest_event_of_input_at(History.t, integer, timestamp) :: Event.t | nil
  def latest_event_of_input_at(history, id, timestamp) do
    case get_in(history.inputs, [id]) do
      nil -> nil
      stream ->
        EventStream.event_at(stream, timestamp)
    end
  end

  @doc """
  Returns the latest `Event.t` that is saved on any input stream.
  If multiple Events happened at the latest point the result is only one of them.
  Returns `nil` if the `history` has no inputs or if on no input an event has happened before
  the `timestamp`.

  ## Examples

      iex> event1 = %Event{stream_id: 1, timestamp: {2, 0, 0}}
      iex> event2 = %Event{stream_id: 1, timestamp: {3, 0, 0}}
      iex> event3 = %Event{stream_id: 2, timestamp: {2, 5, 0}}
      iex> event4 = %Event{stream_id: 2, timestamp: {4, 0, 0}}
      iex> input1_events = [event2, event1]
      iex> input2_events = [event4, event3]
      iex> input1 = %EventStream{id: 1, events: input1_events, progressed_to: {3, 0, 0}}
      iex> input2 = %EventStream{id: 1, events: input2_events, progressed_to: {4, 0, 0}}
      iex> history = %History{inputs: %{input1: input1, input2: input2}}
      iex> History.latest_input_event_at(history, {1, 0, 0})
      nil
      iex> History.latest_input_event_at(history, {3, 0, 0})
      %Event{stream_id: 1, timestamp: {3, 0, 0}}
      iex> History.latest_input_event_at(history, {2, 5, 0})
      %Event{stream_id: 2, timestamp: {2, 5, 0}}
  """
  @spec latest_input_event_at(History.t, timestamp) :: Event.t | nil
  def latest_input_event_at(history, timestamp) do
    events = history.inputs
              |> Map.values
              |> Enum.map(&EventStream.event_at(&1, timestamp))
              |> Enum.filter(&(!is_nil &1))
    if Enum.empty? events do
      nil
    else
      Enum.max_by(events, &(&1.timestamp))
    end
  end

  @doc """
  Returns the latest `Event` in the output of a History or `nil` if the output is empty or `nil`.

  ## Examples

      iex> history = %History{}
      iex> History.latest_output history
      nil

      iex> output = %EventStream{id: 1, progressed_to: {3, 0, 0}}
      iex> history = %History{output: output}
      iex> History.latest_output history
      nil

      iex> event1 = %Event{stream_id: 1, timestamp: {2, 0, 0}}
      iex> event2 = %Event{stream_id: 1, timestamp: {3, 0, 0}}
      iex> events = [event2, event1]
      iex> output = %EventStream{id: 1, progressed_to: {3, 0, 0}, events: events}
      iex> history = %History{output: output}
      iex> History.latest_output history
      %Event{stream_id: 1, timestamp: {3, 0, 0}}

  """
  @spec latest_output(History.t) :: Event.t | nil
  def latest_output(%{output: nil}), do: nil
  def latest_output(history) do
    if Enum.empty? history.output.events do
      nil
    else
      hd history.output.events
    end
  end
end
