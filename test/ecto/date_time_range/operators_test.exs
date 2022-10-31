defmodule Ecto.DateTimeRange.OperatorsTest do
  # @related [subject](/lib/ecto/date_time_range/operators.ex)
  @moduledoc false
  use Test.DataCase, async: true
  import Ecto.DateTimeRange.Operators
  import Ecto.Query
  import Ecto.DateTimeRange, only: [sigil_t: 2]
  alias Ecto.DateTimeRange

  doctest Ecto.DateTimeRange.Operators

  deftemptable :things_with_ranges_temp do
    column(:during_utc, :tstzrange)
    column(:during_naive, :tsrange)
    column(:tid, :string)
  end

  setup do
    create_temp_tables()
    :ok
  end

  defmodule Thing do
    @moduledoc false
    use Ecto.Schema

    schema "things_with_ranges_temp" do
      field(:during_utc, DateTimeRange.UTCDateTime)
      field(:during_naive, DateTimeRange.NaiveDateTime)
      field(:tid, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs),
      do: struct |> cast(attrs, [:during_naive, :during_utc, :tid])
  end

  describe "contains" do
    setup do
      Thing.changeset(%{
        during_naive: ~t{2020-02-02T13:00:00..2020-02-02T14:00:00}N,
        during_utc: ~t{2020-02-02T13:00:00Z..2020-02-02T14:00:00Z},
        tid: "early"
      })
      |> Test.Repo.insert()

      Thing.changeset(%{
        during_naive: ~t{2020-02-02T13:00:00..2020-02-02T14:00:00}N,
        during_utc: ~t{2020-02-02T14:30:00Z..2020-02-02T15:00:00Z},
        tid: "middle"
      })
      |> Test.Repo.insert()

      Thing.changeset(%{
        during_naive: ~t{2020-02-02T13:00:00..2020-02-02T14:00:00}N,
        during_utc: ~t{2020-02-02T15:00:00Z..2020-02-02T15:30:00Z},
        tid: "later"
      })
      |> Test.Repo.insert()

      :ok
    end

    test "queries for records where the given UTC datetime is contained in a record's range" do
      from(_ in Thing, as: :things)
      |> where([things: things], contains(things.during_utc, ^~U[2020-02-02T14:45:00Z]))
      |> Test.Repo.all()
      |> tids()
      |> assert_eq(["middle"])
    end
  end
end
