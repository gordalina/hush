defmodule Hush.Provider.Echo do
  @moduledoc false
  @behaviour Hush.Provider

  def fetch(key), do: {:ok, key}
  def load(_config), do: :ok
end
