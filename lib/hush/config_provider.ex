defmodule Hush.ConfigProvider do
  @behaviour Config.Provider

  @impl Config.Provider
  def init(_), do: nil

  @impl Config.Provider
  def load(config, _), do: Hush.resolve!(config)
end
