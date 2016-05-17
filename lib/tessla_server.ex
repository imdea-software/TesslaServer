defmodule TesslaServer do
  @moduledoc """
  Entry Point for `TesslaServer`
  """
  require Logger

  use Timex

  alias TesslaServer.{SpecProcessor, Event, EventQueue}
  alias TesslaServer.EventQueue

  def main(args) do
    args
    |> parse_args
    |> process
  end

  defp process({options, file}) do
    {:ok, spec} = File.read(file)

    SpecProcessor.process(spec)

    EventQueue.start
    read

  end

  defp read do
    case IO.read(:stdio, :line) do
      :eof -> :ok
      {:error, reason} -> Logger.debug "Error: #{reason}"
      data ->
        data = String.rstrip data, ?\n
        [channel, seconds, microseconds | values] = String.split(data, " ")
        {seconds, _} = Integer.parse(seconds)
        seconds = Time.from(seconds, :seconds)
        {microseconds, _} = Integer.parse(microseconds)
        microseconds = Time.from(microseconds, :microseconds)
        timestamp = Time.add(seconds, microseconds)
        event = %Event{value: values, timestamp: timestamp}
        EventQueue.process_external channel, event
        read()
    end

  end

  defp parse_args(argv) do
    {options, [file],  _} = OptionParser.parse(argv,
     switches: [debug: :boolean]
   )
   Logger.debug inspect options
   {options, file}
  end
end
