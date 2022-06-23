defmodule Ecto.RangeOperators do
  # @related [test](/test/ecto/range_operators_test.exs)

  @moduledoc """
  Provides operators for querying against ranges in PostgreSQL.

  ## Usage

  ```
  import Ecto.Query
  import Ecto.RangeOperators

  now = DateTime.utc_now()
  from(thing in Thing, where: contains(thing.during, ^now))
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
