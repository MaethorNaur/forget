defmodule Forget.Cluster.Manager do
  @moduledoc """
  Manager
  """
  use GenServer
  require Logger

  def start, do: GenServer.start(__MODULE__, :ok, name: via())

  def init(_), do: {:ok, []}

  def add_mnesia_node(node), do: GenServer.call(via(), {:add_node, node})

  def handle_info(message, state) do
    Logger.warn(fn -> "Unhandled message in leader: #{inspect(message)}" end)
    {:noreply, state}
  end

  def terminate(reason, _state) do
    Logger.warn(fn -> "Terminiate leader: #{inspect(reason)}" end)
    :ok
  end

  def handle_call({:add_node, node}, _from, state) do
    log(ProcessRegistry.create_table(), "[Create table]")

    if add_node?(node) do
      log(:mnesia.change_config(:extra_db_nodes, [node]), "[Change config]")

      log(
        :mnesia.add_table_copy(ProcessRegistry.table_name(), node, :ram_copies),
        "[Add table copy]"
      )
    else
      Logger.info(fn -> "[ClusterManager] - Node: #{inspect(node)} already in cluster" end)
    end

    {:reply, :ok, state}
  end

  defp add_node?(node) do
    case :mnesia.transaction(fn ->
           :mnesia.table_info(ProcessRegistry.table_name(), :active_replicas)
         end) do
      {:aborted, _} -> false
      {:atomic, replicas} -> not (node in replicas)
    end
  end

  defp log({:aborted, reason}, context),
  do: Logger.info(fn ->"[ClusterManager] #{context} - Adding node failed: #{inspect(reason)}" end)

  defp log(_result, _context), do: nil

  defp via, do: {:global, __MODULE__}
end
