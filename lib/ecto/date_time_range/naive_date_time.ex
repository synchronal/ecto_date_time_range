defmodule Ecto.DateTimeRange.NaiveDateTime do
  # @related [test](/test/ecto/date_time_range/naive_date_time_test.exs)

  @moduledoc """
  An `Ecto.Type` wrapping a `:tsrange` Postgres column. To the application, it appears as
  a struct with `:start_at` and `:end_at`, with `:naive_datetime` values.

  ```
  defmodule Core.Thing do
    use Ecto.Schema
    import Ecto.Changeset

    schema "things" do
      field :performed_during, Ecto.DateTimeRange.NaiveDateTime
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
  iex> range = ~t[2020-01-01T01:00:00..2020-01-02T01:00:00]N
  ...>
  iex> Ecto.DateTimeRange.NaiveDateTime.contains?(range, ~N[2020-01-01T00:59:59Z])
  false
  iex> Ecto.DateTimeRange.NaiveDateTime.contains?(range, ~N[2020-01-01T01:00:00Z])
  true
  iex> Ecto.DateTimeRange.NaiveDateTime.contains?(range, ~N[2020-01-02T00:59:59Z])
  true
  iex> Ecto.DateTimeRange.NaiveDateTime.contains?(range, ~N[2020-01-02T01:00:00Z])
  false
  iex> Ecto.DateTimeRange.NaiveDateTime.contains?(range, ~N[2020-01-03T01:00:00Z])
  false
  ```
  """
  @spec contains?(t(), NaiveDateTime.t()) :: boolean()
  def contains?(%__MODULE__{start_at: start_at, end_at: end_at}, %NaiveDateTime{} = time) do
    NaiveDateTime.compare(start_at, time) in [:eq, :lt] && NaiveDateTime.compare(end_at, time) == :gt
  end

  @doc """
  Create an `Ecto.DateTimeRange.NaiveDateTime` from two ISO8601 strings.

  ## Example

  ```
  iex> Ecto.DateTimeRange.NaiveDateTime.parse("2020-02-02T00:01:00..2020-02-02T00:01:01")
  {:ok, %Ecto.DateTimeRange.NaiveDateTime{start_at: ~N[2020-02-02T00:01:00], end_at: ~N[2020-02-02T00:01:01]}}

  iex> Ecto.DateTimeRange.NaiveDateTime.parse("2020-02-02T00:01:00..later")
  {:error, "Unable to parse NaiveDateTime(s) from input"}
  ```
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, term()}
  def parse(string) when is_binary(string), do: string |> String.split("..") |> do_parse()

  defp do_parse([%NaiveDateTime{} = lower, %NaiveDateTime{} = upper]),
    do: {:ok, %__MODULE__{start_at: lower, end_at: upper}}

  defp do_parse([{:ok, lower}, {:ok, upper}]), do: [lower, upper] |> do_parse()

  defp do_parse([lower, upper] = times) when is_binary(lower) and is_binary(upper),
    do: times |> Enum.map(&NaiveDateTime.from_iso8601/1) |> do_parse()

  defp do_parse(_), do: {:error, "Unable to parse NaiveDateTime(s) from input"}

  # # # Ecto.Type callbacks

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Declares the native type that will be used in the database."
  def type, do: :tsrange

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Converts user-provided data (for example from a form) to the Elixir term."
  def cast(%{start_at: lower, end_at: upper}) do
    case apply_func({lower, upper}, &Ecto.Type.cast(:naive_datetime, &1)) do
      {:ok, {lower, upper}} ->
        if NaiveDateTime.compare(lower, upper) == :lt,
          do: {:ok, %__MODULE__{start_at: lower, end_at: upper}},
          else: {:error, message: "end time must be later than start time"}

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
        {:ok, %__MODULE__{start_at: lower, end_at: upper}}

      :error ->
        :error
    end
  end

  def load(_), do: :error

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Converts the Elixir term to the Ecto native type."
  def dump(%__MODULE__{start_at: %NaiveDateTime{} = lower, end_at: %NaiveDateTime{} = upper}) do
    {:ok, %Postgrex.Range{lower: lower, upper: upper, upper_inclusive: false}}
  end

  def dump(_), do: :error

  @impl Ecto.Type
  @doc section: :ecto_type
  @doc "Checks if two terms are equal."
  def equal?(%__MODULE__{start_at: lower1, end_at: upper1}, %__MODULE__{
        start_at: lower2,
        end_at: upper2
      }),
      do: NaiveDateTime.compare(lower1, lower2) == :eq && NaiveDateTime.compare(upper1, upper2) == :eq

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
end
