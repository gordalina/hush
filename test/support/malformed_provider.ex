defmodule Hush.Provider.Malformed do
  @moduledoc false
  @behaviour Hush.Provider

  def fetch(_key), do: "wrong return"
  def load(_config), do: :ok
end
