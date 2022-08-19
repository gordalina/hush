defmodule Hush.Resolver do
  @moduledoc """
  Replace configuration with provider-aware resolvers.
  """

  alias Hush.{Cache, Provider, Transformer}

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

    Cache.with(fn ->
      config
      |> preload_secrets(options)
      |> reduce(&values/2)
    end)
  end

  defp preload_secrets(config, options) do
    config
    |> reduce(&flatten/2)
    |> Enum.uniq_by(fn {provider, key, _} -> "#{provider}.#{key}" end)
    |> Task.async_stream(fn {provider, key, opts} -> fetch(provider, key, opts) end, options)
    |> Stream.run()

    config
  end

  defp reduce(config, reducer), do: Enum.reduce(config, [], reducer)

  @spec value!(module(), String.t(), Keyword.t()) :: any()
  defp value!(provider, name, options) do
    case value(provider, name, options) do
      {:ok, value} ->
        value

      {:error, error} ->
        raise RuntimeError,
          message: "Could not resolve {:hush, #{provider}, #{inspect(name)}}: #{error}"
    end
  end

  @spec value(module(), String.t(), Keyword.t()) :: {:ok, any()} | {:error, String.t()}
  defp value(provider, key, options) do
    with {:ok, value} <- fetch(provider, key, options),
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

  @spec default_or_error(Keyword.t()) :: {:ok, any()} | {:error, :required} | {:ok, nil}
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

  defp fetch(provider, key, options) do
    Cache.get("#{provider}.#{key}", options, fn ->
      try do
        Provider.fetch(provider, key)
      rescue
        error ->
          {:error, error.message}
      end
    end)
  end

  defp flatten({:hush, provider, name}, acc), do: acc ++ [{provider, name, []}]
  defp flatten({:hush, provider, name, opts}, acc), do: acc ++ [{provider, name, opts}]
  defp flatten(it, acc) when is_list(it), do: acc ++ reduce(it, &flatten/2)
  defp flatten(it, acc) when is_tuple(it), do: acc ++ (Tuple.to_list(it) |> reduce(&flatten/2))
  defp flatten(it, acc) when is_map(it) and not is_struct(it), do: acc ++ reduce(it, &flatten/2)
  defp flatten(_, acc), do: acc

  defp values({:hush, provider, name}, acc), do: acc ++ [value!(provider, name, [])]
  defp values({:hush, provider, name, opts}, acc), do: acc ++ [value!(provider, name, opts)]
  defp values(it, acc) when is_list(it), do: acc ++ [reduce(it, &values/2)]

  defp values(it, acc) when is_tuple(it),
    do: acc ++ [Tuple.to_list(it) |> reduce(&values/2) |> List.to_tuple()]

  defp values(it, acc) when is_map(it) and not is_struct(it),
    do: acc ++ [reduce(it, &values/2) |> Map.new()]

  defp values(it, acc), do: acc ++ [it]
end
