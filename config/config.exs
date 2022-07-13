import Config

if config_env() == :dev do
  config :elixir, :time_zone_database, Tz.TimeZoneDatabase
end

if config_env() == :test do
  config :ecto, Test.Repo,
    url: "ecto://postgres@localhost/ecto_date_time_range_test",
    pool: Ecto.Adapters.SQL.Sandbox

  config :ecto_date_time_range, Test.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "postgres",
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: 10

  config :ecto_date_time_range,
    ecto_repos: [Test.Repo]

  config :elixir, :time_zone_database, Tz.TimeZoneDatabase
  config :logger, level: :info
end
