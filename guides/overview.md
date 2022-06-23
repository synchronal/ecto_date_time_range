# Overview

`Ecto DateTimeRange` is a library extending Ecto with field types to handle PostgreSQL column types
encapsulating timestamp ranges. The types provided by this library can be paired with view
components in order to facilitate editing ranges in forms.

## Installation

Add the [hex package](https://hex.pm/packages/ecto_date_time_range) to `mix.exs`:

```elixir
def deps do
  [
    {:ecto_date_time_range, "~> 0.1"}
  ]
end
```

If `DateTime`s will be shifted between time zones at any point during the value's lifecycle, for
instance to show/edit timestamps in the time zone reported by a person's browser, then a time zone
database must also be added and configured as Elixir's `:time_zone_database`.

- https://github.com/mathieuprog/tz
- https://github.com/lau/tzdata

## Migrations

Add [migrations](migrations.md) using `:tstzrange` column types.

```elixir
defmodule Core.Repo.Migrations.AddThings do
  use Ecto.Migration

  def change do
    create table(:things) do
      add :performed_during, :tstzrange
    end
  end
end
```

For more detailed information see the [migrations guide](migrations.md).

## Schemas

```elixir
defmodule Core.Thing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "things" do
    field :performed_during, Ecto.UTCDateTimeRange
  end

  @required_attrs ~w[performed_during]a
  def changeset(data \\ %__MODULE__{}, attrs) do
    data
    |> cast(attrs, @required_attrs)
    |> validate_required(@required_attrs)
  end
end
```