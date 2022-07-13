defmodule Ecto.DateTimeRange do
  # @related [subject](/test/ecto/date_time_range_test.exs)

  @moduledoc """
  `Ecto.DateTimeRange` provides modules implementing `Ecto.Type` to allow
  usage of Postgres range times encoding timestamp ranges.
  """

  @doc """
  Create an `Ecto.UTCDateTimeRange` from two ISO8601 strings.

  ## Example

  ```
  iex> import Ecto.DateTimeRange, only: [sigil_t: 2]
  ...>
  iex> ~t(2020-02-02T00:01:00Z..2020-02-02T00:01:01Z)
  %Ecto.UTCDateTimeRange{start_at: ~U[2020-02-02T00:01:00Z], end_at: ~U[2020-02-02T00:01:01Z]}
  ...>
  iex> ~t(hi there)
  ** (ArgumentError) Unable to parse DateTime(s) from input
  ...>
  iex> ~t(00:01:00Z..00:01:01Z)T
  %Ecto.UTCTimeRange{start_at: ~T[00:01:00Z], end_at: ~T[00:01:01Z]}
  ...>
  iex> ~t(00:01:00..00:01:01)t
  %Ecto.DateTimeRange.Time{start_at: ~T[00:01:00], end_at: ~T[00:01:01]}
  ```
  """
  def sigil_t(string, []), do: sigil_t(string, [?U])

  def sigil_t(string, [?U]) when is_binary(string) do
    case Ecto.UTCDateTimeRange.parse(string) do
      {:ok, range} -> range
      {:error, error} -> raise ArgumentError, error
    end
  end

  def sigil_t(string, [?T]) when is_binary(string) do
    case Ecto.UTCTimeRange.parse(string) do
      {:ok, range} -> range
      {:error, error} -> raise ArgumentError, error
    end
  end

  def sigil_t(string, [?t]) when is_binary(string) do
    case Ecto.DateTimeRange.Time.parse(string) do
      {:ok, range} -> range
      {:error, error} -> raise ArgumentError, error
    end
  end
end
