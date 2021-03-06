defmodule Test.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to Postgres.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use EctoTemp, repo: Test.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Test.DataCase
    end
  end

  setup tags do
    Test.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Test.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  def assert_eq(left, right) do
    assert left == right
    left
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc "Retrieve test identifiers from a list of Ecto schemas."
  @spec tids([Ecto.Schema.t()]) :: [binary()]
  def tids(schemas) when is_list(schemas), do: Enum.map(schemas, & &1.tid)
end
