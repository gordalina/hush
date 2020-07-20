defmodule Hush.Provider.SystemEnvironment do
  @moduledoc """
  Provider to resolve runtime environmental variables
  """

  @behaviour Hush.Provider

  @impl Hush.Provider
  @spec load(config :: Keyword.t()) :: :ok | {:error, any()}
  def load(_config), do: :ok

  @impl Hush.Provider
  @spec fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def fetch(key) do
    case System.get_env(key) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end
end
