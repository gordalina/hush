defmodule Hush.Provider do
  @callback load(config :: any()) :: :ok | {:error, any()}
  @callback fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}

  def is?(provider) do
    with {:module, _mod} <- Code.ensure_compiled(provider),
         true <- function_exported?(provider, :fetch, 1)
    do
      :ok
    else
      {:error, error} ->
        {:error, "Provider #{provider} is not available (#{error})"}
      false ->
        {:error, "Provider #{provider}.fetch/1 is undefined"}
    end
  end
end
