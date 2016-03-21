defmodule TesslaServer.Node.Increment do
  use TesslaServer.Node

  def process(event, state) do
    event.description + state.options[:increment]
  end

end
