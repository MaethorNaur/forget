defmodule Forget do
  require Logger

  @moduledoc """
  Documentation for Forget.
  """

  @typedoc """
  Configuration
  """
  @type arg :: {:config, config}

  @typedoc """
  Configuration
  """
  @type init_args :: [arg]

  @typedoc """
  Configuration
  """
  @type config :: [{:schema, term()}, {:cluster, cluster}]

  @type cluster :: [{:quorum, pos_integer()}]
  def init(nodes) do
    with :ok <- ensure_stopped(),
         :ok <- ensure_started() do
      :ok
    else
      {:error, reason} ->
        _ = Logger.debug(fn -> "[mnesiac:#{node()}] #{inspect(reason)}" end)
        {:error, reason}
    end
  end

  defp init_schema(nodes) do
    with {:atomic, :ok} <- :mnesia.change_table_copy_type(:schema, node(), :disc_copies) do
      :ok
    else
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp ensure_dir_exists do
    mnesia_dir = :mnesia.system_info(:directory)

    with false <- File.exists?(mnesia_dir),
         :ok <- File.mkdir(mnesia_dir) do
      :ok
    else
      true -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_stopped do
    with :stopped <- :mnesia.stop(),
         :ok <- wait_for(:stop) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_started do
    with :ok <- :mnesia.start(),
         :ok <- wait_for(:start) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp wait_for(:stop) do
    case :mnesia.system_info(:is_running) do
      :no ->
        :ok

      :yes ->
        {:error, :mnesia_unexpectedly_running}

      :starting ->
        {:error, :mnesia_unexpectedly_starting}

      :stopping ->
        Process.sleep(1_000)
        wait_for(:stop)
    end
  end

  defp wait_for(:start) do
    case :mnesia.system_info(:is_running) do
      :yes ->
        :ok

      :no ->
        {:error, :mnesia_unexpectedly_stopped}

      :stopping ->
        {:error, :mnesia_unexpectedly_stopping}

      :starting ->
        Process.sleep(1_000)
        wait_for(:start)
    end
  end
end
