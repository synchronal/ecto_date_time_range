defmodule Ecto.DateTimeRange.Time do
  # @related [test](/test/ecto/date_time_range/time_test.exs)

  @moduledoc """
  An `Ecto.Type` wrapping a `:tsrange` Postgres column. To the application, it appears as
  a struct with `:start_at` and `:end_at`, with `t:Time.t()` values.

  This type does not do any time zone conversions--times going in will be times coming out.

  ```
  defmodule Core.Thing do
    use Ecto.Schema
    import Ecto.Changeset

    schema "things" do
      field :performed_during, Ecto.DateTimeRange.Time
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
          start_at: Time.t(),
          end_at: Time.t()
        }

  # # #

  @doc """
  Returns true or false depending on whether the time is falls within the
  specified range. **Note:** this assumes that the range is in the same time zone as
  whatever time or date time it is compared against.

  ## Example

  ```
  iex> import Ecto.DateTimeRange
  ...>
  iex> Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[00:00:00])
  false
  iex> Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[01:00:00])
  true
  iex> Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[01:59:59])
  true
  iex> Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[02:00:00])
  false
  ...>
  iex> Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~N[2022-01-01T00:00:00])
  false
  iex> Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~N[2022-01-01T01:00:00])
  true
  ...>
  iex> Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~U[2022-01-01T00:00:00Z])
  false
  iex> Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~U[2022-01-01T01:00:00Z])
  true
  ```
  """
  @spec contains?(t(), DateTime.t() | NaiveDateTime.t() | Time.t()) :: boolean()
  def contains?(%__MODULE__{start_at: start_at, end_at: end_at}, %Time{} = time) do
    if Time.compare(start_at, end_at) == :lt do
      Time.compare(start_at, time) in [:eq, :lt] && Time.compare(end_at, time) == :gt
    else
      Time.compare(start_at, time) in [:eq, :lt] || Time.compare(end_at, time) == :gt
    end
  end

  def contains?(%__MODULE__{} = range, %DateTime{} = date_time),
    do: contains?(range, DateTime.to_time(date_time))

  def contains?(%__MODULE__{} = range, %NaiveDateTime{} = date_time),
    do: contains?(range, NaiveDateTime.to_time(date_time))

  @doc """
  Create an `Ecto.DateTimeRange.Time` from two ISO8601 strings.

  ## Example

  ```
  iex> Ecto.DateTimeRange.Time.parse("00:01:00..00:01:01")
  {:ok, %Ecto.DateTimeRange.Time{start_at: ~T[00:01:00], end_at: ~T[00:01:01]}}

  iex> Ecto.DateTimeRange.Time.parse("00:01:00..later")
  {:error, "Unable to parse Time(s) from input"}
  ```
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, term()}
  def parse(string) when is_binary(string), do: string |> String.split("..") |> do_parse()

  defp do_parse([%Time{} = lower, %Time{} = upper]),
    do: {:ok, %__MODULE__{start_at: lower, end_at: upper}}

  defp do_parse([{:ok, lower}, {:ok, upper}]), do: [lower, upper] |> do_parse()

  defp do_parse([lower, upper] = times) when is_binary(lower) and is_binary(upper),
    do: times |> Enum.map(&Time.from_iso8601/1) |> do_parse()

  defp do_parse(_), do: {:error, "Unable to parse Time(s) from input"}

  # # # Ecto.Type callbacks

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Declares the native type that will be used in the database."
  def type, do: :tsrange

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Converts user-provided data (for example from a form) to the Elixir term."
  def cast(%{start_at: lower, end_at: upper}) do
    case apply_func({lower, upper}, &Ecto.Type.cast(:time, &1)) do
      {:ok, {lower, upper}} ->
        if Time.compare(lower, upper) == :eq,
          do: {:error, message: "end time must be different from start time"},
          else: {:ok, %__MODULE__{start_at: lower, end_at: upper}}

      :error ->
        {:error, message: "unable to read start and/or end times"}
    end
  end

  def cast(%{"start_at" => "", "end_at" => ""}), do: {:ok, nil}

  def cast(%{"start_at" => lower, "end_at" => upper}), do: cast(%{start_at: lower, end_at: upper})
  def cast(_), do: {:error, message: "unable to read start and/or end times"}

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Converts the Ecto native type to the Elixir term."
  def load(%Postgrex.Range{lower: lower, upper: upper}) do
    apply_func({lower, upper}, &Ecto.Type.load(:naive_datetime, &1))
    |> case do
      {:ok, {lower, upper}} ->
        {:ok, %__MODULE__{start_at: NaiveDateTime.to_time(lower), end_at: NaiveDateTime.to_time(upper)}}

      :error ->
        :error
    end
  end

  def load(_), do: :error

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Converts the Elixir term to the Ecto native type."
  def dump(%__MODULE__{start_at: %Time{} = lower, end_at: %Time{} = upper}) do
    lower = to_datetime(lower)
    upper = to_datetime(upper, lower)

    {:ok,
     %Postgrex.Range{
       lower: lower,
       upper: upper,
       upper_inclusive: false
     }}
  end

  def dump(_), do: :error

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Checks if two terms are equal."
  def equal?(%__MODULE__{start_at: lower1, end_at: upper1}, %__MODULE__{
        start_at: lower2,
        end_at: upper2
      }),
      do: Time.compare(lower1, lower2) == :eq && Time.compare(upper1, upper2) == :eq

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

  defp to_datetime(%Time{} = time) do
    time = time |> Time.to_erl()
    date = {0000, 01, 01}
    {date, time} |> NaiveDateTime.from_erl!()
  end

  defp to_datetime(%Time{} = time, %NaiveDateTime{} = lower) do
    time = time |> Time.to_erl()
    date = {0000, 01, 01}
    datetime = {date, time} |> NaiveDateTime.from_erl!()

    if NaiveDateTime.compare(datetime, lower) == :lt,
      do: NaiveDateTime.add(datetime, 60 * 60 * 24, :second),
      else: datetime
  end
end
