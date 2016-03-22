defmodule TesslaServer do
  use Timex

  def main(_args) do
    {:ok, pid_child} = GenServer.start_link(TesslaServer.Node.Increment, %{children: [], stream_name: :error, options: %{increment: 2}})
    {:ok, pid_father} = GenServer.start_link(TesslaServer.Node.Add,  %{children: [pid_child], stream_name: :adder,  options: %{summand1: :input1, summand2: :input2}})
    read(pid_father, pid_child)
  end

  defp read(pid_father, pid_child) do
    case IO.read(:stdio, :line) do
      :eof -> :ok
      {:error, reason} -> IO.puts "Error: #{reason}"
      data ->
        {stream_name, value} = List.to_tuple(String.split(data, " "))
        {value, _} = Integer.parse(value)
        event = %TesslaServer.Event{
          timestamp: Time.now, 
          value: value, 
          stream_name: String.to_atom(stream_name)
        }
        GenServer.cast(pid_father, {:process, event})
        #IO.puts(inspect(:sys.get_status(pid_father)))
        #IO.puts(inspect(:sys.get_status(pid_child)))
        read(pid_father, pid_child)
    end
  end
end
