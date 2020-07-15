defmodule Hush.ConfigProvider do
  @moduledoc """
  This config provider can be attached to your release to run automatically on boot.
  """

  @behaviour Config.Provider

  @impl Config.Provider
  def init(_), do: nil

  @impl Config.Provider
  def load(config, _), do: Hush.resolve!(config)
end
