defmodule Hush.Provider.SystemEnvironment do
  @moduledoc """
  Hush Provider to resolve Environmental Variables
  """

  @behaviour Hush.Provider

  @impl true
  @spec load(config :: any()) :: :ok | {:error, any()}
  def load(_config), do: :ok

  @impl true
  @spec fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}
  def fetch(key) do
    case System.get_env(key) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end
end
