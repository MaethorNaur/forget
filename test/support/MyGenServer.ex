defmodule MyGenServer do
  use GenServer
  def start, do: GenServer.start(__MODULE__, :ok, name: {:global, __MODULE__})
  def init(:ok), do: {:ok, :ok}
  def handle_call(msg, _from, state), do: {:reply, msg, state}
end
