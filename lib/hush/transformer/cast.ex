defmodule Hush.Transformer.Cast do
  @moduledoc """
  Utility functions to cast strings to Elixir native types
  """

  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :cast
  def key(), do: :cast

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform(type, value) do
    try do
      {:ok, to!(type, value)}
    rescue
      error -> {:error, "Couldn't cast to type #{type} due to #{Exception.message(error)}"}
    end
  end

  @doc """
  Cast a string to any type.
  An error is raised on failure.
  """
  def to!(_, value) when not is_binary(value) do
    raise(ArgumentError, message: "Input is not a string")
  end

  @spec to!(:string, String.t()) :: String.t()
  def to!(:string, value), do: value

  @spec to!(:atom, String.t()) :: atom()
  def to!(:atom, value), do: String.to_existing_atom(value)

  @spec to!(:charlist, String.t()) :: charlist()
  def to!(:charlist, value), do: String.to_charlist(value)

  @spec to!(:float, String.t()) :: float()
  def to!(:float, value), do: String.to_float(value)

  @spec to!(:integer, String.t()) :: integer()
  def to!(:integer, value), do: String.to_integer(value)

  @spec to!(:boolean, String.t()) :: boolean()
  def to!(:boolean, value), do: to!(:atom, value)

  @spec to!(:module, String.t()) :: module()
  def to!(:module, value), do: to!(:atom, value)
end
