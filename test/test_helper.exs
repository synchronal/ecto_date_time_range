# Load up the repository, start it, and run migrations
_ = Ecto.Adapters.Postgres.storage_down(Test.Repo.config())

Ecto.Adapters.Postgres.storage_up(Test.Repo.config())
|> case do
  :ok -> :ok
  {:error, :already_up} -> :ok
end

{:ok, _pid} = Test.Repo.start_link()

ExUnit.start()
