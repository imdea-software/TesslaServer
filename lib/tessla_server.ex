defmodule TesslaServer do
  @moduledoc """
  Entry Point for `TesslaServer`
  """
  use Timex

  alias TesslaServer.SpecProcessor
  alias TesslaServer.Source

  def main(args) do
    args
      |> parse_args
      |> process
  end

  defp process({options, file}) do
    {:ok, spec} = File.read(file)

    SpecProcessor.process(spec)

    read

  end

  defp read do
    case IO.read(:stdio, :line) do
      :eof -> :ok
      {:error, reason} -> IO.puts "Error: {reason}"
      data ->
        data = String.rstrip data, ?\n
        [stream_name | values] = String.split(data, " ")
        IO.puts "values: #{inspect values}"
        timestamp = Time.now
        Source.distribute(stream_name, values, timestamp)
        read()
    end

  end

  defp parse_args(argv) do
    {options, [file],  _} = OptionParser.parse(argv,
      switches: [debug: :boolean, spec: :string]
    )
    IO.puts inspect options
    {options, file}
  end
end
