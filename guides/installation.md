# Installation

Add the [hex package](https://hex.pm/packages/ecto_date_time_range) to `mix.exs`:

```elixir
def deps do
  [
    {:ecto_date_time_range, "~> 0.1"}
  ]
end
```

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

For more detailed inforamtion see the [migrations guide](migrations.md).

## Schemas

```elixir
defmodule Core.Thing do
  use Ecto.Schema

  schema "things" do
    field :performed_during, Ecto.UTCDateTimeRange
  end
end
```