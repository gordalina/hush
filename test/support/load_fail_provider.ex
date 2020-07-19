defmodule Hush.Provider.LoadFail do
  @moduledoc false
  @behaviour Hush.Provider

  def fetch(key), do: {:ok, key}
  def load(_config), do: {:error, "fail"}
end
