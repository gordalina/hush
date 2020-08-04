defmodule Hush.Resolver do
  @moduledoc """
  Replace configuration sugin provider-aware resolvers.
  """

  alias Hush.{Cast, Provider}

  @doc """
  Substitute {:hush, Hush.Provider, "key", [options]} present in the the config argument.
  """
  @spec resolve(Keyword.t()) :: {:ok, Keyword.t()} | {:error, any()}
  def resolve(config) do
    try do
      {:ok, resolve!(config)}
    rescue
      err -> {:error, err}
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
    type = Keyword.get(options, :cast, :string)

    with {:ok, value} <- Provider.fetch(provider, name, options),
         {:ok, value} <- Cast.to(type, value),
         {:ok, value} <- to_file?(provider, name, options, value) do
      value
    else
      {:error, :required} ->
        raise ArgumentError,
          message:
            "Could not resolve {:hush, #{provider}, #{inspect(name)}}. If this is an optional key, you add `optional: true` to the options list."

      {:error, :cast} ->
        raise ArgumentError,
          message:
            "Although I was able to resolve {:hush, #{provider}, #{inspect(name)}}, I wasn't able to cast it to type '#{
              type
            }'."

      {:error, error} ->
        raise RuntimeError,
          message:
            "An error occured in the provider while trying to resolve {:hush, #{provider}, #{
              inspect(name)
            }}: #{error}"
    end
  end

  # sobelow_skip ["Traversal.FileModule"]
  @spec to_file?(module(), String.t(), Keyword.t(), any()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp to_file?(_provider, _name, options, value) do
    case Keyword.get(options, :to_file, nil) do
      nil ->
        {:ok, value}

      file ->
        with :ok <- File.write(file, value) do
          {:ok, file}
        end
    end
  end
end
