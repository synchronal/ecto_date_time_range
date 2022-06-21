defmodule Test.Repo do
  use Ecto.Repo, otp_app: :ecto_date_time_range, adapter: Ecto.Adapters.Postgres

  def log(_cmd), do: nil
end
