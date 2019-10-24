defmodule Forget.Application do
  import OK, only: [success: 1, failure: 1, ~>>: 2]
  use Application
  @moduledoc false
  def start(_, _) do
    OK.for do
      topologies <- fetch_env(:libcluster, :topologies)
      config <- fetch_env(:forget, :configuration) ~>> Forget.Configuration.normalise()

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

  def fetch_env(application, key) do
    case Application.fetch_env(application, key) do
      :error -> failure("Missing #{application} configuration")
      success -> success
    end
  end
end
