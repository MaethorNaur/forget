defmodule Forget.Errors do
  def wrap(success_or_error, default \\ nil)
  def wrap(:error, default), do: {:error, default}
  def wrap({:error, _} = error, _default), do: error
  def wrap({:ok, _} = ok, _default), do: ok
  def wrap(ok, _default), do: {:ok, ok}
end
