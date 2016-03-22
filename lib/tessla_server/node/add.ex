defmodule TesslaServer.Node.Add do
  use TesslaServer.Node

  def process(event, state) do
    {summand1, summand2} = get_summands(event, state)
    case add(summand1, summand2) do
      nil -> :wait
      x -> {:ok, %Event{value: x, stream_name: state.stream_name, timestamp: event.timestamp}}
    end
  end

  defp add(nil, _), do: nil
  defp add(_, nil), do: nil
  defp add(summand1, summand2) do
    summand1.value + summand2.value
  end

  defp get_summands(event, state) do
    name_summand1 = state.options.summand1
    name_summand2 = state.options.summand2
    case event.stream_name do
      ^name_summand1 -> { event, History.get_latest_input_of_stream(state.history, state.options.summand2) }
      ^name_summand2 -> { History.get_latest_input_of_stream(state.history, state.options.summand1), event }
      _ -> raise("Event doesn't match a summand stream")
    end
  end
end
