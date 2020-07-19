defmodule Hush.Provider do
  @moduledoc """
  Base implementation for a provider
  """

  @callback load(config :: any()) :: :ok | {:error, any()}
  @callback fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}

  def is?(provider) do
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
