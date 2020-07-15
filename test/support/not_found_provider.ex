defmodule Hush.Provider.NotFound do
  @moduledoc false
  @behaviour Hush.Provider

  def fetch(_key), do: {:error, :not_found}
  def load(_config), do: :ok
end
