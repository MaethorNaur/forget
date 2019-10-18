defmodule Forget.Cluster.ManagerSupervisor do
  use GenServer
  require Logger
  @typep key :: {pid(), reference()}

  @moduledoc """
  Monitor Global process and ensure there is always one process of a kind across the cluster
  """

  @doc """
  Start the `GenServer` 
  """
  @spec start_link :: GenServer.on_start()
  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok), do: {:ok, nil}

  @spec start_manager() :: {:ok, pid()} | {:error, term()}
  def start_manager, do: GenServer.call(__MODULE__, :start_manager)

  @impl true
  def handle_call(:start_manager, _from, state) do
    case do_start_manager() do
      {:ok, {pid, _ref} = new_state} -> {:reply, {:ok, pid}, new_state}
      error -> {:reply, error, state}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, _state) do
    {:noreply, nil}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    case do_start_manager() do
      {:ok, new_state} -> {:noreply, new_state}
      _ -> {:noreply, state}
    end
  end

  @impl true
  def terminate(_reason, {pid, ref}) do
    _ = Process.demonitor(ref)
    _ = :proc_lib.stop(pid, :pid, :infinity)
    :ok
  end

  @spec do_start_manager() :: {:ok, key()} | {:error, term()}
  defp do_start_manager do
    case start_global() do
      {:ok, pid} ->
        ref = Process.monitor(pid)
        {:ok, {pid, ref}}

      error ->
        error
    end
  end

  defp start_global,
    do:
      :global.trans(
        {Forget.Cluster.Manager, Forget.Cluster.Manager},
        fn ->
          case Forget.Cluster.Manager.start() do
            {:ok, pid} ->
              {:ok, pid}

            {:error, {:already_started, pid}} ->
              {:ok, pid}

            {:error, error} ->
              {:error, error}

            error ->
              {:error, {:badargs, error}}
          end
        end,
        Node.list([:visible, :this])
      )
end
