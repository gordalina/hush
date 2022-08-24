defmodule Hush.Resolver do
  @moduledoc """
  Replace configuration with provider-aware resolvers.
  """

  alias Hush.{Provider, Transformer}

  @doc """
  Substitute {:hush, Hush.Provider, "key", [options]} present in the the config argument.
  """
  @spec resolve(Keyword.t()) :: {:ok, Keyword.t()} | {:error, any()}
  def resolve(config, options \\ Keyword.new()) do
    try do
      {:ok, resolve!(config, options)}
    rescue
      e in RuntimeError -> {:error, e.message}
    end
  end

  @doc """
  Substitute {:hush, Hush.Provider, "key", [options]} present in the the config argument
  """
  @spec resolve!(Keyword.t() | map) :: Keyword.t()
  def resolve!(config, options \\ Keyword.new()) do
    options = Keyword.take(options, [:max_concurrency, :timeout])

    cache = config |> fill_cache(options)
    config |> reduce(values(cache))
  end

  defp fill_cache(config, options) do
    config
    |> reduce(&flatten/2)
    |> Stream.uniq_by(fn {provider, key, _} -> hash(provider, key) end)
    |> Task.async_stream(fn {p, k, _} -> {hash(p, k), fetch(p, k)} end, options)
    |> Enum.reduce(%{}, fn {:ok, {k, v}}, acc -> Map.put_new(acc, k, v) end)
  end

  defp value!(provider, name, options, cache) do
    case value(provider, name, options, cache) do
      {:ok, value} ->
        value

      {:error, error} ->
        raise RuntimeError,
          message: "Could not resolve {:hush, #{provider}, #{inspect(name)}}: #{error}"
    end
  end

  defp value(provider, key, options, cache) do
    with {:ok, value} <- fetch(provider, key, cache),
         {:ok, value} <- Transformer.apply(options, value) do
      {:ok, value}
    else
      {:error, :not_found} ->
        default_or_error(options)

      {:error, error} when is_binary(error) ->
        {:error, error}

      {:error, error} ->
        {:error, inspect(error)}
    end
  end

  defp default_or_error(options) do
    cond do
      # lets get default if it exists
      Keyword.has_key?(options, :default) ->
        {:ok, Keyword.get(options, :default)}

      # return nil if optional is set
      Keyword.get(options, :optional, false) ->
        {:ok, nil}

      # return error in any other case
      true ->
        {:error,
         "The provider couldn't find a value for this key. If this is an optional key, you add `optional: true` to the options list."}
    end
  end

  defp fetch(provider, key, cache \\ %{}) do
    case Map.get(cache, hash(provider, key), nil) do
      nil ->
        try do
          Provider.fetch(provider, key)
        rescue
          error -> {:error, error.message}
        end

      cached ->
        cached
    end
  end

  defp flatten({:hush, provider, name}, acc), do: acc ++ [{provider, name, []}]
  defp flatten({:hush, provider, name, opts}, acc), do: acc ++ [{provider, name, opts}]
  defp flatten(it, acc) when is_list(it), do: acc ++ reduce(it, &flatten/2)
  defp flatten(it, acc) when is_tuple(it), do: acc ++ (Tuple.to_list(it) |> reduce(&flatten/2))
  defp flatten(it, acc) when is_map(it) and not is_struct(it), do: acc ++ reduce(it, &flatten/2)
  defp flatten(_, acc), do: acc

  defp hash(provider, key), do: "#{provider}.#{key}"
  defp reduce(config, reducer), do: Enum.reduce(config, [], reducer)

  defp values(cache) do
    fn
      {:hush, provider, name}, acc ->
        acc ++ [value!(provider, name, [], cache)]

      {:hush, provider, name, opts}, acc ->
        acc ++ [value!(provider, name, opts, cache)]

      it, acc when is_list(it) ->
        acc ++ [reduce(it, values(cache))]

      it, acc when is_tuple(it) ->
        acc ++ [Tuple.to_list(it) |> reduce(values(cache)) |> List.to_tuple()]

      it, acc when is_map(it) and not is_struct(it) ->
        acc ++ [reduce(it, values(cache)) |> Map.new()]

      it, acc ->
        acc ++ [it]
    end
  end
end
