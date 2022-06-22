# Migrations

`DateTime` ranges can be indicated in migrations with the `:tstzrange` column type.

```elixir
defmodule Core.Repo.Migrations.AddThings do
  use Ecto.Migration

  def change do
    create table(:things) do
      add :profile_id, references(:profiles), null: false
      add :performed_during, :tstzrange
    end
  end
end
```

`GIST` or `SP-GIST` indexes and constraints can include range operators:

```elixir
defmodule Core.Repo.Migrations.ExcludeOverlappingThings do
  use Ecto.Migration

  def change do
    create constraint(
             :things,
             :no_overlapping_things,
             exclude: ~s|gist (profile_id with =, performed_during with &&)|
           )
  end
end
```