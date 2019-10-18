defmodule Forget.Supervisor do
  @moduledoc """
  Forget supervisor
  """
  use Supervisor
  require Logger

  @doc """
  ```elixir
  config = [
    cluster: [
      
     disc_copies 
    ]
  ]
  ```
  """
  @spec start_link(init_args :: Forget.init_args()) :: :ignore | {:error, term()} | {:ok, pid()}
  def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  @impl true
  def init(_config) do
    children = [
      %{
        id: Forget.Cluster.ManagerSupervisor,
        start: {Forget.Cluster.ManagerSupervisor, :start_link, []}
      },
      %{id: Forget.NodeMonitor, start: {Forget.NodeMonitor, :start_link, []}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
