defmodule EctoDateTimeRange.MixProject do
  use Mix.Project

  @scm_url "https://github.com/synchronal/ecto_date_time_range"

  def application,
    do: [
      extra_applications: [:logger]
    ]

  def project do
    [
      aliases: aliases(),
      app: :ecto_date_time_range,
      deps: deps(),
      description: "Ecto type for PostgreSQL's tstzrange",
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @scm_url,
      name: "Ecto DateTimeRange",
      package: package(),
      preferred_cli_env: [credo: :test, dialyzer: :test],
      source_url: @scm_url,
      start_permanent: Mix.env() == :prod,
      version: "0.1.1"
    ]
  end

  defp aliases,
    do: [
      test: ["ecto.create --quiet", "test"]
    ]

  defp deps,
    do: [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ecto, ">= 3.0.0"},
      {:ecto_sql, "> 3.0.0"},
      {:ecto_temp, "~> 0.1", only: :test},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:markdown_formatter, "~> 0.3", only: :dev, runtime: false},
      {:mix_audit, "~> 1.0", only: :dev, runtime: false},
      {:postgrex, ">= 0.0.0"},
      {:tz, "~> 0.20.1", optional: true}
    ]

  defp dialyzer,
    do: [
      plt_add_apps: [:ex_unit, :inets, :mix],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]

  defp docs,
    do: [
      extra_section: "Guides",
      extras: [
        "guides/overview.md",
        "guides/migrations.md",
        "guides/forms.md",
        "CHANGELOG.md",
        "LICENSE.md"
      ],
      groups_for_functions: [
        "Ecto.Type Callbacks": &(&1[:section] == :ecto_type)
      ],
      main: "overview",
      source_ref: "main"
    ]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package,
    do: [
      files: ~w[
        .formatter.exs
        README.*
        lib
        LICENSE.*
        mix.exs
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @scm_url,
        "Change Log" => "https://hexdocs.pm/ecto_date_time_range/changelog.html"
      },
      maintainers: ["synchronal.dev", "Erik Hanson", "Eric Saxby"]
    ]
end
