defmodule TesslaServer.SpecProcessor.Preprocessor do
  @moduledoc """
  Preprocesses a Tessla Spec

  Removes newlines and unused parts of a spec (e.g. SourceLocation)
  """

  @spec process(String.t) :: String.t
  def process(spec) do
    spec
      |> String.downcase
      |> String.replace(~r/,\s*sourceloc\(\s*\(\s*[0-9]+,[0-9]+\s-\s[0-9]+,[0-9]+\s*\)\s*\)/, " ")
  end
end
