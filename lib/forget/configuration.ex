defmodule Forget.Configuration do
  import OK, only: [success: 1, failure: 1]
  @error failure("Not a valid forget configuration")

  @type t :: [cluster: cluster()]
  @typep cluster :: []

  @spec normalise(config :: term()) :: {:ok, t()} | {:error, term()}
  def normalise(config) when is_list(config) do
    OK.for do
      cluster <- config |> Keyword.fetch(:cluster) |> wrap_error
      normalised <- normalise_cluster?(cluster)
    after
      [cluster: normalised]
    end
  end
  def normalise(_config), do: @error

  defp wrap_error(:error), do: @error
  defp wrap_error(success), do: success

  defp normalise_cluster?(cluster) when is_list(cluster) do
    {:ok, cluster}
  end
  defp normalise_cluster?(_cluster), do: @error

end
