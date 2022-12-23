[
  {Medic.Checks.Asdf, :plugin_installed?, ["postgres"]},
  {Medic.Checks.Asdf, :package_installed?, ["postgres"]},
  {Medic.Checks.Hex, :local_hex_installed?},
  {Medic.Checks.Hex, :local_rebar_installed?},
  {Medic.Checks.Hex, :packages_installed?},
  {Medic.Checks.Postgres, :running?, [remedy: "bin/dev/db-start", username: System.fetch_env!("USER")]},
  {Medic.Checks.Postgres, :role_exists?},
  {Medic.Checks.Postgres, :correct_version_running?, [remedy: "bin/dev/db-restart"]},
  {Medic.Checks.Postgres, :correct_data_directory?, [remedy: "bin/dev/db-restart"]}
]
