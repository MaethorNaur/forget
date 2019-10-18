defmodule ForgetTest do
  @moduledoc false
  use ExUnit.ClusteredCase
  require Logger

  def start_app(_context) do
    # {:ok, _} = Forget.Supervisor.start_link(config: 1)
  end

  scenario "test", cluster_size: 3, stdout: :standard_io, capture_log: true do
    node_setup(:start_app)

    test "always pass", %{cluster: cluster} do
      [a, b, c] = Cluster.members(cluster)

      Cluster.call(a, :mnesia, :create_schema, [[a, b]])
      |> IO.inspect()

      [a, b]
      |> Enum.each(&Cluster.call(&1, :mnesia, :start, []))

      # Cluster.call(a, :mnesia, :change_table_copy_type, [:schema, a, :disc_copies])
      # |> IO.inspect()
      #
      # Cluster.call(a, :mnesia, :change_config, [:extra_db_nodes, [b]]) |> IO.inspect()
      # Cluster.call(a, :mnesia, :add_table_copy, [:schema, b, :disc_copies]) |> IO.inspect()

      Cluster.call(c, :mnesia, :start, []) |> IO.inspect()
      Cluster.call(a, :mnesia, :change_config, [:extra_db_nodes, [c]]) |> IO.inspect()

      Cluster.call(a, :mnesia, :change_table_copy_type, [:schema, c, :disc_copies])
      |> IO.inspect()

      cluster
      |> Cluster.members()
      |> Enum.each(&Cluster.call(&1, :mnesia, :system_info, []))

      assert true
    end
  end
end
