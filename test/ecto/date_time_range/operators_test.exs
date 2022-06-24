defmodule Ecto.DateTimeRange.OperatorsTest do
  # @related [subject](/lib/ecto/date_time_range/operators.ex)
  @moduledoc false
  use Test.DataCase, async: true
  import Ecto.DateTimeRange.Operators
  import Ecto.Query
  import Ecto.UTCDateTimeRange, only: [sigil_t: 2]
  alias Ecto.UTCDateTimeRange

  doctest Ecto.DateTimeRange.Operators

  deftemptable :things_with_time_ranges do
    column(:during, :tstzrange)
    column(:tid, :string)
  end

  setup do
    create_temp_tables()
    :ok
  end

  defmodule Thing do
    @moduledoc false
    use Ecto.Schema

    schema "things_with_time_ranges_temp" do
      field(:during, UTCDateTimeRange)
      field(:tid, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs),
      do: struct |> cast(attrs, [:during, :tid])
  end

  describe "contains" do
    setup do
      Thing.changeset(%{during: ~t{2020-02-02T13:00:00Z - 2020-02-02T14:00:00Z}, tid: "early"}) |> Test.Repo.insert()
      Thing.changeset(%{during: ~t{2020-02-02T14:30:00Z - 2020-02-02T15:00:00Z}, tid: "middle"}) |> Test.Repo.insert()
      Thing.changeset(%{during: ~t{2020-02-02T15:00:00Z - 2020-02-02T15:30:00Z}, tid: "later"}) |> Test.Repo.insert()
      :ok
    end

    test "queries for records where the given timestamp is contained in a record's range" do
      time = ~U[2020-02-02T14:45:00Z]

      from(_ in Thing, as: :things)
      |> where([things: things], contains(things.during, ^time))
      |> Test.Repo.all()
      |> tids()
      |> assert_eq(["middle"])
    end
  end
end
