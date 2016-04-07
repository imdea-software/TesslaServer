defmodule TesslaServer.SpecProcessor.Parser do
  @moduledoc """
  Invokes the parser on the lexed input
  """

  def parse(tokens) do
    # Enum.each(tokens, &(IO.puts(inspect(&1))))
    case :tessla_parser.parse tokens do
      {:ok, parsed } -> parsed
      {:error, {line, _, reason}} ->
        raise("Invalid spec at line #{inspect line}, reason: #{inspect reason}" )
    end
  end
end
