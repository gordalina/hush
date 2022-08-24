defmodule Hush.Provider do
  @moduledoc """
  Hush relies on providers to resolve values that the consumer requests.

  You can [read here](https://hexdocs.pm/hush/readme.html#writing-your-own-provider) on how to write your own provider.
  """

  @type child_spec :: Supervisor.child_spec()

  @callback load(config :: Keyword.t()) :: :ok | {:ok, [child_spec()]} | {:error, any()}
  @callback fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}

  @doc """
  Fetch a value from a provider
  """
  @spec fetch(module(), String.t()) ::
          {:ok, String.t() | nil} | {:error, :required} | {:error, any()}
  def fetch(provider, name) do
    with :ok <- valid?(provider),
         {:ok, value} <- provider.fetch(name) do
      {:ok, value}
    else
      {:error, error} ->
        {:error, error}

      unexpected ->
        {:error,
         "Provider returned an unexpected value: #{inspect(unexpected)}.\nExpected {:ok, value}, {:error, :not_found} or {:error, \"string\"}"}
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
end
