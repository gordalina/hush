defmodule Hush.Provider.Echo do
  @behaviour Hush.Provider

  def fetch(key), do: {:ok, key}
  def load(_config), do: :ok
end
