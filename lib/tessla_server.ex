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
      {:error, reason} -> Logger.debug "Error: {reason}"
      data ->
        data = String.rstrip data, ?\n
        [stream_name | values] = String.split(data, " ")
        stream_name = String.to_atom stream_name
        Logger.debug "values: #{inspect values}"
        timestamp = Time.now
        event = %Event{value: values, timestamp: timestamp}
        EventQueue.process_external event
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
