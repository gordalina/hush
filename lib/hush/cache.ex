defmodule Hush.Cache do
  @moduledoc """
  Simple cache to hold secrets
  """

  def with(fun) do
    ensure_table_exists()
    result = fun.()
    delete_table()
    result
  end

  def get(key, opts, fun) do
    ensure_table_exists()

    case lookup(key) do
      {:error, :not_found} ->
        cache_apply(key, opts, fun)

      result ->
        result
    end
  end

  defp ensure_table_exists() do
    try do
      :ets.new(__MODULE__, [:named_table, :public, :set])
    rescue
      _ -> __MODULE__
    end
  end

  defp delete_table() do
    :ets.delete_all_objects(__MODULE__)
  end

  defp lookup(key) do
    case :ets.lookup(__MODULE__, key) do
      [result | _] -> check_freshness(result)
      [] -> {:error, :not_found}
    end
  end

  defp check_freshness({_, result, expiration}) do
    case expiration > System.monotonic_time(:millisecond) do
      true -> result
      _ -> {:error, :not_found}
    end
  end

  defp cache_apply(key, opts, fun) do
    case fun.() do
      {:ok, _} = result ->
        expiration = System.monotonic_time(:millisecond) + cache_ttl(opts)
        :ets.insert(__MODULE__, {key, result, expiration})
        result

      other ->
        other
    end
  end

  defp cache_ttl(opts) do
    default = Application.get_env(:hush, :cache_ttl, 60_000)
    Keyword.get(opts, :cache_ttl, default)
  end
end
