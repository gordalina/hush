defmodule Hush.Resolver do
  @moduledoc """
  Replace configuration sugin provider-aware resolvers.
  """

  alias Hush.{Provider, Transformer}

  @doc """
  Substitute {:hush, Hush.Provider, "key", [options]} present in the the config argument.
  """
  @spec resolve(Keyword.t()) :: {:ok, Keyword.t()} | {:error, any()}
  def resolve(config) do
    try do
      {:ok, resolve!(config)}
    rescue
      e in RuntimeError -> {:error, e.message}
      e -> {:error, inspect(e)}
    end
  end

  @doc """
  Substitute {:hush, Hush.Provider, "key", [options]} present in the the config argument
  """
  @spec resolve!(Keyword.t() | map) :: Keyword.t()
  def resolve!(config) do
    Enum.reduce(config, [], &reducer/2)
  end

  @spec reducer(any(), Keyword.t()) :: Keyword.t()
  defp reducer({:hush, provider, name}, acc) do
    acc ++ [value!(provider, name, [])]
  end

  defp reducer({:hush, provider, name, options}, acc) do
    acc ++ [value!(provider, name, options)]
  end

  defp reducer(rest, acc) when is_list(rest) do
    acc ++ [rest |> resolve!()]
  end

  defp reducer(rest, acc) when is_map(rest) do
    if Enumerable.impl_for(rest) != nil do
      acc ++ [rest |> resolve!() |> Map.new()]
    else
      acc ++ [rest]
    end
  end

  defp reducer(rest, acc) when is_tuple(rest) do
    acc ++ [Tuple.to_list(rest) |> resolve!() |> List.to_tuple()]
  end

  defp reducer(other, acc) do
    acc ++ [other]
  end

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
  defp value(provider, name, options) do
    try do
      with {:ok, value} <- Provider.fetch(provider, name, options),
           {:ok, value} <- Transformer.apply(options, value) do
        {:ok, value}
      else
        {:error, :required} ->
          {:error,
           "The provider couldn't find a value for this key. If this is an optional key, you add `optional: true` to the options list."}

        {:error, error} when is_binary(error) ->
          {:error, error}

        {:error, error} ->
          {:error, inspect(error)}
      end
    rescue
      error ->
        {:error, error.message}
    end
  end
end
