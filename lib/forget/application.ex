defmodule Forget.Application do
  use Application
  @moduledoc false
  def start(_, _) do
    children = [
      %{id: Forget.Supervisors.Global, start: {Forget.Supervisors.Global, :start_link, []}}
      # %{id: Forget.NodeMonitor, start: {Forget.NodeMonitor, :start_link, []}}
    ]

    opts = [strategy: :one_for_one, name: Forget.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
