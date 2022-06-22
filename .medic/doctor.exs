[
  {Medic.Checks.Asdf, :plugin_installed?, ["postgres"]},
  {Medic.Checks.Asdf, :package_installed?, ["postgres"]},
  {Medic.Checks.Hex, :local_hex_installed?},
  {Medic.Checks.Hex, :local_rebar_installed?},
  {Medic.Checks.Hex, :packages_installed?},
  {Medic.Checks.Postgres, :running?}
  # {Medic.Checks.Postgres, :correct_version_running?},
  # {Medic.Checks.Postgres, :role_exists?},
  # {Local.Checks.Postgres, :correct_data_directory?},
]
