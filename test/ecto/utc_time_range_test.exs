defmodule Ecto.UTCTimeRangeTest do
  # @related [subject](/lib/ecto/utc_time_range.ex)
  @moduledoc false
  use Test.DataCase, async: true
  alias Ecto.UTCTimeRange

  doctest Ecto.UTCTimeRange

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
      field(:during, UTCTimeRange)
      field(:tid, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs),
      do: struct |> cast(attrs, [:during])
  end

  describe "inserting data" do
    test "casts empty strings to nil" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{"start_at" => "", "end_at" => ""}
               })
               |> Test.Repo.insert()

      assert thing.during |> is_nil()

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(nil)
    end

    test "is ok if the value is a time range in iso8601" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => "00:01:01Z",
                   "end_at" => "00:02:01Z"
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCTimeRange{
               start_at: ~T[00:01:01Z],
               end_at: ~T[00:02:01Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCTimeRange{
        start_at: ~T[00:01:01Z],
        end_at: ~T[00:02:01Z]
      })
    end

    test "assumes UTC if the range does not include the time zone" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{"start_at" => "00:01", "end_at" => "00:02"}
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCTimeRange{
               start_at: ~T[00:01:00Z],
               end_at: ~T[00:02:00Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCTimeRange{
        start_at: ~T[00:01:00Z],
        end_at: ~T[00:02:00Z]
      })
    end

    test "casts to UTC if the range specifies a different time zone" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => "13:00",
                   "end_at" => "15:00",
                   "tz" => "America/Los_Angeles"
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCTimeRange{
               start_at: ~T[21:00:00.000000Z],
               end_at: ~T[23:00:00.000000Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCTimeRange{
        start_at: ~T[21:00:00Z],
        end_at: ~T[23:00:00Z]
      })
    end

    test "is ok if the value is a time range of Times" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~T[00:01:01Z],
                   "end_at" => ~T[00:02:01Z]
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCTimeRange{
               start_at: ~T[00:01:01Z],
               end_at: ~T[00:02:01Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCTimeRange{
        start_at: ~T[00:01:01Z],
        end_at: ~T[00:02:01Z]
      })
    end

    test "sets end_at to the following day if 'earlier' than start_at" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~T[00:02:01Z],
                   "end_at" => ~T[00:01:01Z]
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCTimeRange{
               start_at: ~T[00:02:01Z],
               end_at: ~T[00:01:01Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCTimeRange{
        start_at: ~T[00:02:01Z],
        end_at: ~T[00:01:01Z]
      })

      {:ok, %{rows: [[_, during, _]]}} = Test.Repo.query("select * from things_with_time_ranges_temp")

      during
      |> assert_eq(%Postgrex.Range{
        lower: ~U[0000-01-01 00:02:01.000000Z],
        lower_inclusive: true,
        upper: ~U[0000-01-02 00:01:01.000000Z],
        upper_inclusive: false
      })
    end

    test "is an error if the value is not a start and end time" do
      assert {:error, changeset} = Thing.changeset(%{"during" => "five"}) |> Test.Repo.insert()
      assert %{during: ["unable to read start and/or end times"]} = errors_on(changeset)
    end

    test "is an error if the end is equal to the start" do
      assert {:error, changeset} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~T[00:01:01Z],
                   "end_at" => ~T[00:01:01Z]
                 }
               })
               |> Test.Repo.insert()

      assert %{during: ["end time must be different from start time"]} = errors_on(changeset)
    end

    test "accepts a UTCTimeRange struct" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 during: %UTCTimeRange{
                   start_at: ~T[13:00:00Z],
                   end_at: ~T[14:00:00Z]
                 }
               })
               |> Test.Repo.insert()

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCTimeRange{
        start_at: ~T[13:00:00Z],
        end_at: ~T[14:00:00Z]
      })
    end
  end
end
