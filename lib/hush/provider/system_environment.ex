defmodule Hush.Provider.SystemEnvironment do
  @behaviour Hush.Provider

  @spec load(config :: any()) :: :ok | {:error, any()}
  def load(_config), do: :ok

  @spec fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}
  def fetch(key) do
    case System.get_env(key) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end
end
