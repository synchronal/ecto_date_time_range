defmodule Ecto.DateTimeRange do
  @moduledoc """
  Wraps a tstzrange Postgres column. To the application, it appears as
  a struct with `:start_at` and `:end_at`, with `:utc_datetime` values.
  """
end
