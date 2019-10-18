defmodule Forget.Supervisors.GlobalTest do
  alias Forget.Supervisors.Global

  use ExUnit.ClusteredCase

  def start_app(_context) do
    {:ok, _app} = Application.ensure_all_started(:forget)
    :global.sync()
  end

  scenario "Global supervisor", cluster_size: 2, stdout: :standard_io, capture_log: true do
    node_setup(:start_app)

    test "Start genserver once", %{cluster: cluster} do
      [node_a, node_b] = Cluster.members(cluster)

      {:ok, pid} = Cluster.call(node_a, Global, :start_child, [{MyGenServer, :start, []}])

      assert is_pid(pid)

      assert Cluster.call(node_b, GenServer, :call, [{:global, MyGenServer}, "test"]) == "test"

      {:ok, pid2} = Cluster.call(node_b, Global, :start_child, [{MyGenServer, :start, []}])

      assert pid == pid2
    end

    test "Restart genserver once if stopped with an abnormal reason", %{cluster: cluster} do
      [node_a, node_b] = Cluster.members(cluster)

      {:ok, pid} = Cluster.call(node_a, Global, :start_child, [{MyGenServer, :start, []}])
      Cluster.call(node_b, GenServer, :stop, [{:global, MyGenServer}, :kill])
      Process.sleep(50)

      assert Cluster.call(node_b, GenServer, :call, [{:global, MyGenServer}, "test"]) == "test"
      {:ok, pid2} = Cluster.call(node_a, Global, :start_child, [{MyGenServer, :start, []}])
      {:ok, pid3} = Cluster.call(node_b, Global, :start_child, [{MyGenServer, :start, []}])
      assert is_pid(pid) and is_pid(pid2) and is_pid(pid3) and pid != pid2 and pid2 == pid3
    end

    test "Not restart the GenServer if normally stopped", %{cluster: cluster} do
      [node_a, node_b] = Cluster.members(cluster)

      {:ok, pid} = Cluster.call(node_a, Global, :start_child, [{MyGenServer, :start, []}])
      assert is_pid(pid)
      Cluster.call(node_b, GenServer, :stop, [{:global, MyGenServer}])
      Process.sleep(50)

      assert Cluster.call(node_b, GenServer, :call, [{:global, MyGenServer}, "test", 10]) ==
               {:exit, {:noproc, {GenServer, :call, [{:global, MyGenServer}, "test", 10]}}}
    end
  end
end
