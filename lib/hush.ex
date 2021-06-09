defmodule Hush do
  @moduledoc """
  Extensible runtime configuration loader with pluggable providers
  """

  @doc """
  Resolve configuration

  When called with resolve!/0 it will default to all loaded applications' configuration.
  When called with resolve!/1 with the configuration as an arugment it will process that.
  """
  @spec resolve!() :: Keyword.t()
  def resolve!() do
    runtime_config() |> resolve!()
  end

  @spec resolve!(Keyword.t()) :: Keyword.t()
  def resolve!(config) when is_list(config) do
    config |> load_providers!()
    config |> Enum.map(&resolve!(&1))
  end

  @spec resolve!({atom(), Keyword.t()}) :: {atom(), Keyword.t()}
  def resolve!({app, config}) do
    with config <- Hush.Resolver.resolve!(config),
         :ok <- Application.put_all_env([{app, config}]) do
      {app, config}
    end
  end

  @doc """
  Is the app running in release mode?
  """
  @spec release_mode?() :: boolean()
  def release_mode? do
    !function_exported?(Mix, :env, 0)
  end

  @spec load_providers!(Keyword.t()) :: Keyword.t()
  defp load_providers!(config) do
    for provider <- providers(config) do
      case provider.load(config) do
        {:error, message} ->
          raise ArgumentError, "Could not load provider #{provider}: #{message}"

        _ ->
          :ok
      end
    end
  end

  @spec providers(Keyword.t()) :: Keyword.t()
  defp providers(config) do
    config
    |> Keyword.get(:hush, providers: [])
    |> Keyword.get(:providers, [])
  end

  @spec runtime_config() :: Keyword.t()
  defp runtime_config() do
    for {app, _, _} <- Application.loaded_applications() do
      {app, Application.get_all_env(app)}
    end
  end
end
