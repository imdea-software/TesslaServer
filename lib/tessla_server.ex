defmodule TesslaServer do
  use Timex

  alias TesslaServer.SpecProcessor
  alias TesslaServer.Event
  
  import TesslaServer.Registry

  def main(_args) do

    {:ok, spec} = File.read("test/examples/minimal.tessla")

    SpecProcessor.process(spec)

    event = %Event{value: "minimal.c:test(0,1,2)", stream_name: :'function_call:minimal.c:test'}
    
    IO.puts "sending event"

    GenServer.cast(via_tuple(:test_calls), {:process, event}) 

    :timer.sleep(100000) # Needed for script testing, else it will temrinate
    # will be replaced by event loop of course

  end
end
