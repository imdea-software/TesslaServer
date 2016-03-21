defmodule TesslaServer do
  use Timex

  def main(_args) do
    {:ok, pid_child} = GenServer.start_link(TesslaServer.Node.Increment, %{children: [], options: %{increment: 2}})
    {:ok, pid_father} = GenServer.start_link(TesslaServer.Node.Increment,  %{children: [pid_child], options: %{increment: 5}})
    read(pid_father, pid_child)
  end

  defp read(pid_father, pid_child) do
    case IO.read(:stdio, :line) do
      :eof -> :ok
      {:error, reason} -> IO.puts "Error: #{reason}"
      data ->
        {desc, _} = Integer.parse(data)
        event = %TesslaServer.Event{timestamp: Time.now, description: desc}
        GenServer.cast(pid_father, {:process, event})
        IO.puts(inspect(:sys.get_status(pid_father)))
        IO.puts(inspect(:sys.get_status(pid_child)))
        read(pid_father, pid_child)
    end
  end
end
