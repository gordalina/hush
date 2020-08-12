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
      err -> {:error, err.message}
    end
  end

  @doc """
  Substitute {:hush, Hush.Provider, "key", [options]} present in the the config argument
  """
  @spec resolve!(Keyword.t() | map) :: Keyword.t()
  def resolve!(config) do
    Enum.reduce(config, [], fn
      {:hush, provider, name}, acc ->
        acc ++ [resolve_value!(provider, name, [])]

      {:hush, provider, name, options}, acc ->
        acc ++ [resolve_value!(provider, name, options)]

      rest, acc when is_list(rest) ->
        acc ++ [rest |> resolve!()]

      rest, acc when is_map(rest) ->
        if Enumerable.impl_for(rest) != nil do
          acc ++ [rest |> resolve!() |> Map.new()]
        else
          acc ++ [rest]
        end

      rest, acc when is_tuple(rest) ->
        acc ++ [Tuple.to_list(rest) |> resolve!() |> List.to_tuple()]

      other, acc ->
        acc ++ [other]
    end)
  end

  @spec resolve_value!(module(), String.t(), Keyword.t()) :: any()
  defp resolve_value!(provider, name, options) do
    case resolve_value(provider, name, options) do
      {:ok, value} ->
        value

      {:error, error} ->
        raise RuntimeError,
          message: "Could not resolve {:hush, #{provider}, #{inspect(name)}}: #{error}"
    end
  end

  defp resolve_value(provider, name, options) do
    try do
      with {:ok, value} <- Provider.fetch(provider, name, options),
           {:ok, value} <- Transformer.apply(options, value) do
        {:ok, value}
      else
        {:error, :cast} ->
          {:error, "cast error"}

        {:error, :required} ->
          {:error,
           "The provider couldn't find a value for this key. If this is an optional key, you add `optional: true` to the options list."}

        {:error, error} ->
          {:error, error}
      end
    rescue
      error ->
        {:error, error.message}
    end
  end
end
