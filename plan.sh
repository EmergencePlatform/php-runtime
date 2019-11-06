pkg_name=php-runtime
pkg_origin=emergence
pkg_version="0.3"
pkg_maintainer="Chris Alfano <chris@jarv.us>"
pkg_license=("MIT")
pkg_build_deps=(
  jarvus/toml-merge
)
pkg_deps=(
  core/bash
  core/git
  emergence/php5
  emergence/php-core
)

pkg_bin_dirs=(bin)

pkg_binds=(
  [database]="port username password"
)

pkg_exports=(
  [port]=network.port
)


do_setup_environment() {
  set_runtime_env -f PHPRC "${pkg_svc_config_install_path}"
}

do_before() {
  # adjust PHP_EXTENSION_DIR after env is initially built
  set_runtime_env -f PHP_EXTENSION_DIR "${pkg_svc_config_install_path}/extensions-${PHP_ZEND_API_VERSION}"
}

do_build() {
  return 0
}

do_install() {
  build_line "Creating command wrappers"

  cat > "${pkg_prefix}/bin/emergence-php-exec" <<- EOM
#!/bin/sh
exec ${pkg_svc_config_path}/fpm-exec \$@
EOM

  cat > "${pkg_prefix}/bin/emergence-php-load" <<- EOM
#!/bin/sh

if [ "\$1" == '--stdin' ]; then
  shift
  EXEC_OPTIONS='--stdin'
fi

exec emergence-php-exec \$EXEC_OPTIONS PUT load.php \$@
EOM

  chmod +x "${pkg_prefix}/bin"/*
}

do_build_config() {
  do_default_build_config

  build_line "Merging php5 config"
  cp -nrv "$(pkg_path_for emergence/php5)"/{config_install,config,hooks} "${pkg_prefix}/"
  toml-merge \
    "$(pkg_path_for emergence/php5)/default.toml" \
    "${PLAN_CONTEXT}/default.toml" \
    > "${pkg_prefix}/default.toml"
}

do_strip() {
  return 0
}