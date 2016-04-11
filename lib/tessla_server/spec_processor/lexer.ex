defmodule TesslaServer.SpecProcessor.Lexer do
  @moduledoc """
  Lexes the cleaned and structured tessla spec
  """

  def lex(spec) do
    # IO.puts spec
    {_, tokens, _} = spec
                      |> String.to_char_list
                      |> :tessla_lexer.string
    tokens
  end

end
