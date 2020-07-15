defmodule Hush.Provider.NotFound do
  @behaviour Hush.Provider

  def fetch(_key), do: {:error, :not_found}
  def load(_config), do: :ok
end
