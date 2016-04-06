defmodule TesslaServer do
  use Timex

  alias TesslaServer.SpecProcessor
  alias TesslaServer.Source

  def main(_args) do

    {:ok, spec} = File.read("test/examples/minimal.tessla")

    SpecProcessor.process(spec)

    read
  end

  defp read() do
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
end
