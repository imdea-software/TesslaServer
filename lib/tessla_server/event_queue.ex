defmodule TesslaServer.EventQueue do
  @moduledoc """
  Implements a central EventQueue to process all external Events in a strictly ordered way.
  """

  use Timex
  alias TesslaServer.Source
  alias __MODULE__

  @type t :: %__MODULE__{progressed_to: Timex.Types.timestamp}
  defstruct progressed_to: Duration.zero

  def start do
    Agent.start_link(fn -> %EventQueue{} end, name: __MODULE__)
  end

  @spec process_external(String.t, Event.t) :: :ok
  def process_external(channel, event) do
    progress_to event.timestamp
    Source.distribute channel, event
  end

  @spec progress_to(Timex.Duration.t) :: :ok | no_return
  defp progress_to(timestamp) do
    Agent.update(__MODULE__, fn queue = %{progressed_to: progressed_to} ->
      if Timex.after? progressed_to, timestamp do
        raise "External Event received out of order #{inspect timestamp}, progress: #{inspect progressed_to}"
      end
      %{queue | progressed_to: timestamp}
    end)
  end
end
