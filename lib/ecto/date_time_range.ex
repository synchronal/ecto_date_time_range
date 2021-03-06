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
  %Ecto.DateTimeRange.UTCDateTime{start_at: ~U[2020-02-02T00:01:00Z], end_at: ~U[2020-02-02T00:01:01Z]}
  ...>
  iex> ~t(2020-02-02T00:01:00Z..2020-02-02T00:01:01Z)U
  %Ecto.DateTimeRange.UTCDateTime{start_at: ~U[2020-02-02T00:01:00Z], end_at: ~U[2020-02-02T00:01:01Z]}
  ...>
  iex> ~t(2020-02-02T00:01:00..2020-02-02T00:01:01)N
  %Ecto.DateTimeRange.NaiveDateTime{start_at: ~N[2020-02-02T00:01:00], end_at: ~N[2020-02-02T00:01:01]}
  ...>
  iex> ~t(00:01:00..00:01:01)T
  %Ecto.DateTimeRange.Time{start_at: ~T[00:01:00], end_at: ~T[00:01:01]}
  ...>
  iex> ~t(hi there)
  ** (ArgumentError) Unable to parse DateTime(s) from input
  ```
  """
  def sigil_t(string, []), do: sigil_t(string, [?U])

  def sigil_t(string, [?U]) when is_binary(string) do
    case Ecto.DateTimeRange.UTCDateTime.parse(string) do
      {:ok, range} -> range
      {:error, error} -> raise ArgumentError, error
    end
  end

  def sigil_t(string, [?N]) when is_binary(string) do
    case Ecto.DateTimeRange.NaiveDateTime.parse(string) do
      {:ok, range} -> range
      {:error, error} -> raise ArgumentError, error
    end
  end

  def sigil_t(string, [?T]) when is_binary(string) do
    case Ecto.DateTimeRange.Time.parse(string) do
      {:ok, range} -> range
      {:error, error} -> raise ArgumentError, error
    end
  end
end
