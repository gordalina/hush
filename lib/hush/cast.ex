defmodule Hush.Cast do
  @moduledoc """
  Utility functions to cast `String`s to Elixir native types
  """

  @type type_atom :: :string | :atom | :charlist | :float | :integer | :boolean | :module
  @type type_native ::
          String.t() | atom() | charlist() | float() | integer() | boolean() | module()

  @doc """
  Cast a string to any type.
  Returns an {:error, :cast} tuple on failure
  """
  @spec to(type_atom, String.t()) :: {:ok, type_native} | {:error, :cast, type_atom}
  def to(type, value) do
    try do
      {:ok, to!(type, value)}
    rescue
      _ -> {:error, :cast}
    end
  end

  @doc """
  Cast a string to any type.
  An error is returned on failure.
  """
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
