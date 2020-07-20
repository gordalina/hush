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
  @spec resolve!(Keyword.t()) :: Keyword.t()
  def resolve!(config) do
    Enum.reduce(config, [], fn
      {key, {:hush, provider, name}}, acc ->
        acc ++ [{key, resolve_value!(key, provider, name, [])}]

      {key, {:hush, provider, name, options}}, acc ->
        acc ++ [{key, resolve_value!(key, provider, name, options)}]

      {key, rest = [_ | _]}, acc ->
        acc ++ [{key, resolve!(rest)}]

      other, acc ->
        acc ++ [other]
    end)
  end

  @spec resolve_value!(String.t(), module(), String.t(), Keyword.t()) :: any()
  defp resolve_value!(key, provider, name, options) do
    type = Keyword.get(options, :cast, :string)

    with {:ok, value} <- Provider.fetch(provider, name, options),
         {:ok, value} <- Cast.to(type, value) do
      value
    else
      {:error, :required} ->
        raise ArgumentError,
          message:
            "Could not resolve required configuration '#{key}'. I was trying to evaluate '#{name}' with #{
              provider
            }."

      {:error, :cast} ->
        raise ArgumentError,
          message:
            "Although I was able to resolve configuration '#{key}', I wasn't able to cast it to type '#{
              type
            }'."

      {:error, error} ->
        raise RuntimeError,
          message:
            "An error occured while trying to resolve value in provider: #{provider}.\n#{error}"
    end
  end
end
