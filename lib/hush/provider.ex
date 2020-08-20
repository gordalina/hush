defmodule Hush.Provider do
  @moduledoc """
  Hush relies on providers to resolve values that the consumer requests.

  You can [read here](https://hexdocs.pm/hush/readme.html#writing-your-own-provider) on how to write your own provider.
  """

  @callback load(config :: Keyword.t()) :: :ok | {:error, any()}
  @callback fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}

  @doc """
  Fetch a value from a provider
  """
  @spec fetch(module(), String.t(), Keyword.t()) ::
          {:ok, String.t() | nil} | {:error, :required} | {:error, any()}
  def fetch(provider, name, options \\ []) do
    with :ok <- valid?(provider),
         {:ok, value} <- provider.fetch(name) do
      {:ok, value}
    else
      {:error, :not_found} ->
        default_or_error(options)

      {:error, error} ->
        {:error, error}

      unexpected ->
        {:error,
         "Provider returned an unexpected value: #{unexpected}.\nExpected {:ok, value}, {:error, :not_found} or {:error, \"error\"}"}
    end
  end

  @doc """
  Is the provider a valid one?
  """
  @spec valid?(module()) :: :ok | {:error, String.t()}
  def valid?(provider) do
    with {:module, _mod} <- Code.ensure_compiled(provider),
         true <- function_exported?(provider, :fetch, 1) do
      :ok
    else
      {:error, error} ->
        {:error, "Provider is not available (#{error})"}

      false ->
        {:error, "Provider's fetch/1 is undefined"}
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
        {:error, :required}
    end
  end
end
