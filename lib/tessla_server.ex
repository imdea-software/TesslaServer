defmodule TesslaServer do
  @moduledoc """
  Entry Point for `TesslaServer`
  """
  require Logger

  use Timex

  alias TesslaServer.{SpecProcessor, Event, EventQueue, Output}
  alias TesslaServer.EventQueue

  def main(args) do
    args
    |> parse_args
    |> process
  end

  defp process({options, file}) do
    {:ok, spec} = File.read(file)

    options
    |> Keyword.get_values(:outputs)
    |> Enum.map(&String.split(&1, ":"))
    |> make_tuple_list
    |> Enum.into(%{})
    |> Output.start

    SpecProcessor.process(spec)

    EventQueue.start

    case Keyword.get(options, :trace) do
      nil -> read_io
      trace -> read_trace_file trace
    end
  end

  defp read_io do
    case IO.read(:stdio, :line) do
      :eof -> :ok
      {:error, reason} -> Logger.debug "Error: #{reason}"
      data ->
        distribute_trace data
        read_io
    end
  end

  @spec generate_event(String.t) :: {String.t, Event.t}
  defp generate_event(line) do
    line = String.rstrip line, ?\n
    [channel, value, seconds, microseconds] = String.split(line, " ")
    {seconds, _} = Integer.parse(seconds)
    seconds = Time.from(seconds, :seconds)
    {microseconds, _} = Integer.parse(microseconds)
    microseconds = Time.from(microseconds, :microseconds)
    timestamp = Time.add(seconds, microseconds)
    {channel, %Event{value: value, timestamp: timestamp}}
  end

  defp read_trace_file(trace_file) do
    traces = File.open!(trace_file)
    traces_by_line = IO.stream(traces, :line)
    Enum.each traces_by_line, &distribute_trace(&1)
  end

  defp distribute_trace(trace) do
    {channel, event} = generate_event trace
    EventQueue.process_external channel, event
  end

  defp parse_args(argv) do
    {options, [spec],  _} = OptionParser.parse(argv,
     strict: [debug: :boolean, trace: :string, outputs: :keep],
     aliases: [d: :debug, t: :trace, o: :outputs]
   )
   {options, spec}
  end

  defp make_tuple_list(list) do
    for [key, val] <- list do
      {id, ""} = Integer.parse(key)
      {id, val}
    end
  end
end
