defmodule Ecto.DateTimeRange.UTCDateTime do
  # @related [test](/test/ecto/date_time_range/utc_date_time_test.exs)

  @moduledoc """
  An `Ecto.Type` wrapping a `:tstzrange` Postgres column. To the application, it appears as
  a struct with `:start_at` and `:end_at`, with `:utc_datetime` values.

  ```
  defmodule Core.Thing do
    use Ecto.Schema
    import Ecto.Changeset

    schema "things" do
      field :performed_during, Ecto.DateTimeRange.UTCDateTime
    end

    @required_attrs ~w[performed_during]a
    def changeset(data \\ %__MODULE__{}, attrs) do
      data
      |> cast(attrs, @required_attrs)
      |> validate_required(@required_attrs)
    end
  end
  ```
  """

  @behaviour Access
  @behaviour Ecto.Type

  defstruct ~w{start_at end_at}a

  @type t() :: %__MODULE__{
          start_at: DateTime.t(),
          end_at: DateTime.t()
        }

  # # #

  @doc """
  Returns true or false depending on whether the time is falls within the
  specified range.

  ## Example

  ```
  iex> import Ecto.DateTimeRange
  iex> range = ~t[2020-01-01T01:00:00Z..2020-01-02T01:00:00Z]U
  ...>
  iex> Ecto.DateTimeRange.UTCDateTime.contains?(range, ~U[2020-01-01T00:59:59Z])
  false
  iex> Ecto.DateTimeRange.UTCDateTime.contains?(range, ~U[2020-01-01T01:00:00Z])
  true
  iex> Ecto.DateTimeRange.UTCDateTime.contains?(range, ~U[2020-01-02T00:59:59Z])
  true
  iex> Ecto.DateTimeRange.UTCDateTime.contains?(range, ~U[2020-01-02T01:00:00Z])
  false
  iex> Ecto.DateTimeRange.UTCDateTime.contains?(range, ~U[2020-01-03T01:00:00Z])
  false
  ```
  """
  @spec contains?(t(), DateTime.t()) :: boolean()
  def contains?(%__MODULE__{start_at: start_at, end_at: end_at}, %DateTime{} = time) do
    DateTime.compare(start_at, time) in [:eq, :lt] && DateTime.compare(end_at, time) == :gt
  end

  @doc """
  Create an `Ecto.DateTimeRange.UTCDateTime` from two ISO8601 strings.

  ## Example

  ```
  iex> Ecto.DateTimeRange.UTCDateTime.parse("2020-02-02T00:01:00Z..2020-02-02T00:01:01Z")
  {:ok, %Ecto.DateTimeRange.UTCDateTime{start_at: ~U[2020-02-02T00:01:00Z], end_at: ~U[2020-02-02T00:01:01Z]}}

  iex> Ecto.DateTimeRange.UTCDateTime.parse("2020-02-02T00:01:00Z..later")
  {:error, "Unable to parse DateTime(s) from input"}
  ```
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, term()}
  def parse(string) when is_binary(string), do: string |> String.split("..") |> do_parse()

  defp do_parse([%DateTime{} = lower, %DateTime{} = upper]),
    do: {:ok, %__MODULE__{start_at: lower, end_at: upper}}

  defp do_parse([{:ok, lower, _}, {:ok, upper, _}]), do: [lower, upper] |> do_parse()

  defp do_parse([lower, upper] = times) when is_binary(lower) and is_binary(upper),
    do: times |> Enum.map(&DateTime.from_iso8601/1) |> do_parse()

  defp do_parse(_), do: {:error, "Unable to parse DateTime(s) from input"}

  # # # Ecto.Type callbacks

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Declares the native type that will be used in the database."
  def type, do: :tstzrange

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Converts user-provided data (for example from a form) to the Elixir term."

  def cast(%{start_at: lower_iso8601, end_at: upper_iso8601, tz: tz})
      when is_binary(lower) and is_binary(upper) do
    with {:ok, lower, _} <- DateTime.from_iso8601(lower_iso8601),
         {:ok, upper, _} <- DateTime.from_iso8601(upper_iso8601) do
      cast(%{start_at: lower, end_at: upper, tz: tz})
    else
      _ ->
        {:error, message: "unable to read start and/or end times"}
    end
  end

  def cast(%{start_at: lower, end_at: upper, tz: tz}) do
    case apply_func({lower, upper}, &Ecto.Type.cast(:naive_datetime, &1)) do
      {:ok, {lower, upper}} ->
        if NaiveDateTime.compare(lower, upper) == :lt,
          do: {:ok, %__MODULE__{start_at: utc(lower, tz), end_at: utc(upper, tz)}},
          else: {:error, message: "end time must be later than start time"}

      :error ->
        {:error, message: "unable to read start and/or end times"}
    end
  end

  def cast(%{start_at: lower, end_at: upper}),
    do:
      cast(%{
        start_at: DateTime.shift_zone!(lower, "Etc/UTC"),
        end_at: DateTime.shift_zone!(upper, "Etc/UTC"),
        tz: "Etc/UTC"
      })

  def cast(%{"start_at" => "", "end_at" => ""}), do: {:ok, nil}

  def cast(%{"start_at" => lower, "end_at" => upper, "tz" => tz}),
    do: cast(%{start_at: lower, end_at: upper, tz: tz})

  def cast(%{"start_at" => lower, "end_at" => upper}), do: cast(%{start_at: lower, end_at: upper})
  def cast(_), do: {:error, message: "unable to read start and/or end times"}

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Converts the Ecto native type to the Elixir term."
  def load(%Postgrex.Range{lower: lower, upper: upper}) do
    apply_func({lower, upper}, &Ecto.Type.load(:utc_datetime, &1))
    |> case do
      {:ok, {lower, upper}} ->
        {:ok, %__MODULE__{start_at: lower, end_at: upper}}

      :error ->
        :error
    end
  end

  def load(_), do: :error

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Converts the Elixir term to the Ecto native type."
  def dump(%__MODULE__{start_at: %DateTime{} = lower, end_at: %DateTime{} = upper}) do
    {:ok, %Postgrex.Range{lower: lower, upper: upper, upper_inclusive: false}}
  end

  def dump({%NaiveDateTime{} = lower, upper}) do
    dump({DateTime.from_naive!(lower, "Etc/UTC"), upper})
  end

  def dump({lower, %NaiveDateTime{} = upper}) do
    dump({lower, DateTime.from_naive!(upper, "Etc/UTC")})
  end

  def dump(_), do: :error

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Checks if two terms are equal."
  def equal?(%__MODULE__{start_at: lower1, end_at: upper1}, %__MODULE__{
        start_at: lower2,
        end_at: upper2
      }),
      do: DateTime.compare(lower1, lower2) == :eq && DateTime.compare(upper1, upper2) == :eq

  def equal?(first, second), do: first == second

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Declares than when used in embedded schemas, the type will be dumped before being encoded."
  def embed_as(_), do: :dump

  # # # Access

  @impl Access
  def fetch(map, key), do: :maps.find(key, map)

  @impl Access
  def get_and_update(map, key, fun), do: Map.get_and_update(map, key, fun)

  @impl Access
  def pop(data, key), do: {Map.get(data, key), data}

  # # # Private

  defp apply_func({lower, upper}, fun) do
    lower = do_apply_func(lower, fun)
    upper = do_apply_func(upper, fun)

    if lower != :error and upper != :error do
      {:ok, {lower, upper}}
    else
      :error
    end
  end

  defp do_apply_func(target, fun) do
    case fun.(target) do
      {:ok, target} -> target
      :error -> :error
    end
  end

  defp utc(%NaiveDateTime{} = time, tz),
    do: DateTime.from_naive!(time, tz) |> DateTime.shift_zone!("Etc/UTC")
end
