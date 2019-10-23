defmodule Forget.Application do
  require OK
  use Application
  @moduledoc false
  def start(_, _) do
    OK.for do
      topologies <-
        Application.fetch_env(:libcluster, :topologies)
        |> wrap("Missing libcluster configuration")

      config <- Application.fetch_env(:forget, :config) |> wrap("Missing forget configuration")

      children = [
        %{
          id: Forget.ClusterSupervisor,
          start:
            {Cluster.Supervisor, :start_link, [[topologies, [name: Forget.ClusterSupervisor]]]}
        },
        %{id: Forget.Supervisor, start: {Forget.Supervisor, :start_link, [config]}}
        # %{id: Forget.NodeMonitor, start: {Forget.NodeMonitor, :start_link, []}}
      ]

      opts = [strategy: :one_for_one, name: Forget.ApplicationSupervisor]

      pid <- Supervisor.start_link(children, opts)
    after
      pid
    end
  end

  defp wrap(:error, default), do: {:error, default}
  defp wrap({:ok, _} = ok, _default), do: ok
end
