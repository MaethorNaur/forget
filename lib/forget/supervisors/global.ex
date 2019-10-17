defmodule Forget.Supervisors.Global do
  use GenServer
  require Logger
  @typep key :: {pid(), reference()}
  @typep start_child :: {:ok, pid()} | {:error, term()}
  @type child_spec :: {module(), atom(), [term()]} | {module(), atom()}

  @moduledoc """
  Monitor Global process and ensure there is always one process of a kind across the cluster
  """

defmacro start(args) do
 quote do
   GenServer.star 
  end 
end

  @doc """
  Start the `GenServer` 
  """
  @spec start_link :: GenServer.on_start()
  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    _ = :ets.new(:forget_global_processes, [:private, :named_table])
    {:ok, :forget_global_processes}
  end

  @spec start_child(child_spec :: child_spec()) :: {:ok, pid()} | {:error, term()}
  def start_child({module, function}) when is_atom(module) and is_atom(function),
    do: start_child({module, function, []})

  def start_child({module, function, args} = child_spec)
      when is_atom(module) and is_atom(function) and is_list(args),
      do: GenServer.call(__MODULE__, {:start_child, child_spec})

  def start_child(child_spec), do: {:error, {:badargs, child_spec}}

  @impl true
  def handle_call({:start_child, child_spec}, _from, ets_table) do
    {:reply, do_start_child(child_spec, ets_table), ets_table}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, :normal}, ets_table) do
    true = :ets.delete(ets_table, {pid, ref})
    {:noreply, ets_table}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, _reason}, ets_table) do
    :ok = restart_process({pid, ref}, ets_table)
    {:noreply, ets_table}
  end

  def find_module_of_process({pid, ref} = key, ets_table) do
    case :ets.lookup(ets_table, key) do
      [{{^pid, ^ref}, module_args}] -> {:ok, module_args}
      _ -> {:error, :process_not_found}
    end
  end

  defp restart_process({_pid, _ref} = key, ets_table) do
    with {:ok, child_spec} <- find_module_of_process(key, ets_table),
         {:ok, _pid} <- restart_process(key, child_spec, ets_table) do
      :ok
    else
      error ->
        _ = Logger.warn(fn -> inspect(error) end)
        :ok
    end
  end

  @spec restart_process(key :: key(), child_spec :: child_spec(), ets_table :: atom()) ::
          start_child()
  defp restart_process(key, child_spec, ets_table) do
    true = :ets.delete(ets_table, key)
    do_start_child(child_spec, ets_table)
  end

  @impl true
  def terminate(_reason, ets_table) do
    :ok =
      lazy_get_keys_from_ets_table(ets_table)
      |> Stream.each(fn {_pid, ref} -> Process.demonitor(ref) end)
      |> Stream.run()

    true = :ets.delete(ets_table)
    :ok
  end

  defp lazy_get_keys_from_ets_table(ets_table) do
    eot = :"$end_of_table"

    Stream.resource(
      fn -> [] end,
      fn acc ->
        case acc do
          [] ->
            case :ets.first(ets_table) do
              ^eot -> {:halt, acc}
              first_key -> {[first_key], first_key}
            end

          acc ->
            case :ets.next(ets_table, acc) do
              ^eot -> {:halt, acc}
              next_key -> {[next_key], next_key}
            end
        end
      end,
      fn _acc -> :ok end
    )
  end

  @spec do_start_child(child_spec :: child_spec()) :: {:ok, key()} | {:error, term()}
  defp do_start_child(child_spec) do
    case start_global(child_spec) do
      {:ok, pid} ->
        ref = Process.monitor(pid)
        {:ok, {pid, ref}}

      error ->
        error
    end
  end

  @spec do_start_child(child_spec :: child_spec(), ets_table :: atom()) :: start_child()
  defp do_start_child(child_spec, ets_table) do
    with {:ok, {pid, ref}} <- do_start_child(child_spec),
         true <- :ets.insert(ets_table, {{pid, ref}, child_spec}) do
      {:ok, pid}
    else
      false ->
        {:error, "Module already started"}

      error ->
        error
    end
  end

  defp start_global({module, function_name, args}),
    do:
      :global.trans(
        {module, module},
        fn ->
          case apply(module, function_name, args) do
            {:ok, pid} ->
              {:ok, pid}

            {:error, {:already_started, pid}} ->
              {:ok, pid}

            {:error, error} ->
              {:error, error}

            error ->
              {:error, {:badargs, error}}
          end
        end,
        Node.list([:visible, :this])
      )
end
