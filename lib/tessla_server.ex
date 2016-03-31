defmodule TesslaServer do
  use Timex

  alias TesslaServer.SpecProcessor

  def main(_args) do

    {:ok, spec} = File.read("test/examples/full.tessla")

    thing = SpecProcessor.process(spec)

    """
    {:ok, pid_multiplier} = GenServer.start_link(TesslaServer.Node.Multiply, %{children: [], stream_name: :multiplier, options: %{factor1: :adder1, factor2: :adder2}})
    {:ok, pid_adder2} = GenServer.start_link(TesslaServer.Node.Add, %{children: [pid_multiplier], stream_name: :adder2, options: %{summand1: :input3, summand2: :input4}})
    {:ok, pid_adder1} = GenServer.start_link(TesslaServer.Node.Add,  %{children: [pid_multiplier], stream_name: :adder1,  options: %{summand1: :input1, summand2: :input2}})


    
    {:ok, input1} = GenServer.start_link(TesslaServer.Source, %{name: :input1, children: [pid_adder1]}) 
    {:ok, input2} = GenServer.start_link(TesslaServer.Source, %{name: :input2, children: [pid_adder1]}) 
    {:ok, input3} = GenServer.start_link(TesslaServer.Source, %{name: :input3, children: [pid_adder2]}) 
    {:ok, input4} = GenServer.start_link(TesslaServer.Source, %{name: :input4, children: [pid_adder2]}) 

    inputs = %{
      input1: input1,
      input2: input2,
      input3: input3,
      input4: input4
    }

    read(inputs)
  end

  defp read(inputs) do
    case IO.read(:stdio, :line) do
      :eof -> :ok
      {:error, reason} -> IO.puts "Error: {reason}"
      data ->
        {stream_name, value} = List.to_tuple(String.split(data, " "))
        {value, _} = Integer.parse(value)
        event = %TesslaServer.Event{
          timestamp: Time.now,
          value: value
        }
        Map.get(inputs, String.to_atom(stream_name)) |> GenServer.cast({:new_event, event})
        read(inputs)
    end
    """
    true
  end
end
