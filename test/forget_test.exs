defmodule ForgetTest do
  @moduledoc false
  use ExUnit.ClusteredCase
  require Logger

  def start_app(_context) do
    {:ok, _} = Forget.Supervisor.start_link(config: 1)
  end

  scenario "test", cluster_size: 2, stdout: :standard_io, capture_log: true do
    node_setup(:start_app)

    test "always pass", %{cluster: cluster} do
      [a,b] = Cluster.members(cluster)
      Cluster.call(a, Node, :disconnect, [b])
      cluster
      |> Cluster.members()
      |> Enum.each(fn node ->
        {node, Cluster.log(node)} |> inspect() |> Logger.info()
      end)

      assert true
    end
  end
end
