defmodule Hush.Provider.FileSystem do
  @moduledoc """
  Provider to read secrets from file system
  """

  @behaviour Hush.Provider

  @impl true
  @spec load(config :: Keyword.t()) :: :ok | {:error, any()}
  def load(_config), do: :ok

  @impl true
  @spec fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def fetch(key) do
    case File.read(key) do
      {:error, :enoent} -> {:error, :not_found}
      {:ok, value} -> {:ok, value}
    end
  end
end
