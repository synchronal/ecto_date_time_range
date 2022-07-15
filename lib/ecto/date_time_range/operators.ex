defmodule Ecto.DateTimeRange.Operators do
  # @related [test](/test/ecto/date_time_range/operators_test.exs)

  @moduledoc """
  Provides operators for querying against ranges in PostgreSQL.

  ## Usage

  ```
  import Ecto.Query
  import Ecto.DateTimeRange.Operators

  now = DateTime.utc_now()
  from(thing in Thing, where: contains(thing.during, ^now))
  ```
  """

  @doc """
  Filter by rows where the given datetime falls within the range.

  ## Examples

  ```
  from(thing in Thing, where: contains(thing.during_utc, ^DateTime.utc_now()))
  ```
  """
  defmacro contains(field, datetime) do
    quote do:
            fragment(
              "cast(? as timestamp with time zone) <@ ?",
              unquote(datetime),
              unquote(field)
            )
  end
end
