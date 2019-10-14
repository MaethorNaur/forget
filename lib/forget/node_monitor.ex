defmodule Forget.NodeMonitor do
  use GenServer
  require Logger
  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    :ok = :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, []}
  end

  def handle_info(msg, state) do
    :ok = Logger.info(inspect(msg))
    {:noreply, state}
  end
end
