defmodule TesslaServer.Computation.InputBuffer do
  @moduledoc """
  Functionality to buffer inputs to a computations and get the next
  events to compute.
  """

  use Timex

  alias TesslaServer.{Event, GenComputation}
  alias __MODULE__

  defstruct input_queues: %{}
  @type t :: %__MODULE__{input_queues: queue}
  @typep queue :: %{GenComputation.id => [Event.t]}
  @type event_map :: %{GenComputation.id => Event.t}

  @doc """
  Sets up a new `InputBuffer` with empty queues for the given `ids`.
  """
  @spec new([GenComputation.id]) :: InputBuffer.t
  def new(ids) do
    input_queues = ids
                   |> Enum.map(&({&1, []}))
                   |> Map.new
    %InputBuffer{input_queues: input_queues}
  end

  @doc """
  Adds an `event` to the appropriate queue in the `buffer`.
  If the `buffer` wasn't initialized with the `id` of the `event` en error
  will be raised.
  """
  @spec add_event(InputBuffer.t, Event.t) :: InputBuffer.t
  def add_event(buffer, event) do
    updated_inputs = Map.update buffer.input_queues, event.stream_id, [event], fn queue ->
      queue ++ [event]
    end
    %{buffer | input_queues: updated_inputs}
  end

  @doc """
  Determines if the buffer holds enough events to progress.
  This means that there is an event present on each queues.
  """
  @spec can_progress?(InputBuffer.t) :: boolean
  def can_progress?(buffer) do
    buffer.input_queues
    |> Map.values
    |> Enum.any?(&Enum.empty?(&1))
    |> Kernel.not
  end

  @doc """
  Splits the `buffer` into an event map, containing all events of the queues
  at the minimal timestamp of all queues.
  If `can_progress?` returns `true` for the buffer, this function is guaranteed to
  return a non empty event_map, else the event_map will be nil and the buffer
  will be returned unmodified.
  """
  @spec pop_head(InputBuffer.t) :: {event_map | nil, Duration.t | nil, InputBuffer.t}
  def pop_head(buffer) do
    if can_progress? buffer do
      minimal_timestamp = minimal_timestamp buffer
      pop_head_at buffer, minimal_timestamp
    else
      {nil, nil, buffer}
    end
  end

  @spec pop_head_at(InputBuffer.t, Duration.t | :literal) :: {event_map, InputBuffer.t}
  defp pop_head_at(buffer, timestamp) do
    partitioned = buffer.input_queues
                  |> Enum.map(&pop_event_at_timestamp(&1, timestamp))
                  |> Map.new
    to_process = partitioned |> Map.keys |> Enum.reduce(%{}, &Map.merge/2)
    input_queues = partitioned |> Map.values |> Enum.reduce(%{}, &Map.merge/2)

    updated_buffer = %{buffer | input_queues: input_queues}
    {to_process, timestamp, updated_buffer}
  end

  @spec pop_event_at_timestamp({GenComputation.id, [Event.t]}, Duration.t | :literal) ::
  {event_map, queue}
  defp pop_event_at_timestamp({stream_id, [head]}, :literal) do
    {%{stream_id => head}, %{stream_id => []}}
  end
  defp pop_event_at_timestamp({stream_id, queue = [head | tail]}, timestamp) do
    cond do
      head.timestamp == :literal ->
        {%{stream_id => head}, %{stream_id => queue}}
      head.timestamp == timestamp ->
        {%{stream_id => head}, %{stream_id => tail}}
      true ->
        {%{}, %{stream_id => queue}}
    end
  end

  @spec minimal_timestamp(InputBuffer.t) :: Duration.t | :literal
  defp minimal_timestamp(buffer) do
    timestamps = buffer.input_queues
    |> Map.values
    |> Enum.map(&hd/1)
    |> Enum.map(&(&1.timestamp))
    |> Enum.reject(&(&1 == :literal))

    if Enum.empty? timestamps do
      :literal
    else
      timestamps
      |> Enum.map(&Duration.to_erl/1)
      |> Enum.min
      |> Duration.from_erl
    end
  end
end
