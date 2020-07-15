defmodule Hush.Provider.Malformed do
  @behaviour Hush.Provider

  def fetch(_key), do: "wrong return"
  def load(_config), do: :ok
end
