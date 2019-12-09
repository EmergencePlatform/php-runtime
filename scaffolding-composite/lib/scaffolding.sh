# scaffolding lifecycle:
scaffolding_load() {
  # ensure source is local
  if [ -n "${pkg_source}" ]; then
      exit_with "Please do not use pkg_source in your plan when using scaffolding." 10
  fi

  # ensure composite_app_pkg_name is defined
  if [ -z "${composite_app_pkg_name}" ]; then
      exit_with "Plan must configure composite_app_pkg_name to pkg_name of app" 10
  fi

  # ensure composite_app_pkg_origin is defined
  if [ -z "${composite_app_pkg_origin}" ]; then
      composite_app_pkg_origin="${pkg_origin}"
      build_line "Setting composite_app_pkg_origin=${composite_app_pkg_origin}"
  fi

  # ensure composite_mysql_pkg is defined
  if [ -z "${composite_mysql_pkg}" ]; then
      composite_mysql_pkg="core/mysql"
      build_line "Setting composite_mysql_pkg=${composite_mysql_pkg}"
  fi

  # prepend runtime deps
  pkg_deps=(
    "${composite_app_pkg_origin}/${composite_app_pkg_name}"
    jarvus/habitat-compose
    "${composite_mysql_pkg}"
    emergence/nginx
    "${pkg_deps[@]}"
  )

  # composite service must run as root
  pkg_svc_user="root"
  build_line "Setting pkg_svc_user=${pkg_svc_user}"

  # configure service command
  if [ -z "${pkg_svc_run}" ]; then
    pkg_svc_run="habitat-compose ${pkg_svc_config_path}/services.json"
    build_line "Setting pkg_svc_run=${pkg_svc_run}"
  fi

  # swap in do_default_build_config
  _rename_function "do_default_build_config" "_stock_do_default_build_config"
  _rename_function "_new_do_default_build_config" "do_default_build_config"
}

scaffolding_detect_pkg_version() {
  echo "$(pkg_path_for ${composite_app_pkg_origin}/${composite_app_pkg_name})" | cut -d / -f 6
}


# scaffolding internal methods:
# copied from https://github.com/habitat-sh/core-plans/blob/master/scaffolding-node/lib/scaffolding.sh
_rename_function() {
  local orig_name new_name
  orig_name="$1"
  new_name="$2"

  declare -F "$orig_name" > /dev/null \
    || exit_with "No function named $orig_name, aborting" 97
  eval "$(echo "${new_name}()"; declare -f "$orig_name" | tail -n +2)"
}

# override default build lifecycle steps for consumer plans:
do_default_before() {
  # initialize pkg_version
  update_pkg_version
}

do_default_build() {
  return 0
}

do_default_install() {
  return 0
}

# this function gets renamed to `do_default_build_config`
_new_do_default_build_config() {
  _stock_do_default_build_config

  build_line "Merging habitat-compose config"
  cp -nrv "$(pkg_path_for jarvus/habitat-compose)/config" "${pkg_prefix}/"
  toml-merge \
    "$(pkg_path_for jarvus/habitat-compose)/default.toml" \
    - \
    "${PLAN_CONTEXT}/default.toml" \
    > "${pkg_prefix}/default.toml" <<- END_OF_TOML
      [services]
        [services.app]
        pkg_name = '${composite_app_pkg_name}'
          [services.app.binds]
            database = 'mysql'
        [services.mysql]
          pkg_ident = '${composite_mysql_pkg}'
        [services.nginx]
          pkg_ident = 'emergence/nginx'
          [services.nginx.binds]
            backend = 'app'
END_OF_TOML
}

do_default_strip() {
  return 0
}
