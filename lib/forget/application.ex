defmodule Forget.Application do
  use Application
  require OK
  import Forget.Errors
  @moduledoc false
  def start(_, _) do
    OK.for do
      # topologies <- Application.fetch_env(:libcluster, :topologies) |> wrap("Missing libcluster configuration")
      # config <- Application.fetch_env(:forget, :config) |> wrap("Missing forget configuration")
      topologies = []
      config = []
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
end
