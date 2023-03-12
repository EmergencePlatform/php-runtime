pkg_name=php-runtime
pkg_origin=emergence
pkg_version='0.0.1'
pkg_maintainer="Chris Alfano <chris@jarv.us>"
pkg_license=("MIT")
pkg_build_deps=(
  jarvus/toml-merge
)
php_pkg_ident="emergence/php5"
pkg_deps=(
  core/bash
  core/git
  "${php_pkg_ident}"
  emergence/php-core
)

pkg_bin_dirs=(bin)

pkg_binds=(
  [database]="port username password"
)

pkg_exports=(
  [port]=network.port
  # [root]=nginx.root
  # [index]=nginx.index
  [status_path]=path.status
  [nginx_server_snippet]=nginx.server_snippet
)


do_setup_environment() {
  set_runtime_env -f PHPRC "${pkg_svc_config_install_path}"
  set_runtime_env -f MYSQL_HOME "${pkg_svc_config_path}"
}

do_before() {
  # adjust PHP_EXTENSION_DIR after env is initially built
  set_runtime_env -f PHP_EXTENSION_DIR "${pkg_svc_config_install_path}/extensions-${PHP_ZEND_API_VERSION}"
}

do_build() {
  return 0
}

do_install() {
  build_line "Installing web root"
  mkdir -p "${pkg_prefix}/web/public"
  cp -rv "${PLAN_CONTEXT}/web"/* "${pkg_prefix}/web/"

  build_line "Generating initialize.php wrapper"
  cat > "${pkg_prefix}/web/initialize.php" <<- EOM
<?php

require('${pkg_svc_config_path}/initialize.php');
EOM

  build_line "Installing bin commands"
  cp -v "${PLAN_CONTEXT}/bin"/* "${pkg_prefix}/bin/"

  build_line "Generating emergence-php-exec wrapper"
  cat > "${pkg_prefix}/bin/emergence-php-exec" <<- EOM
#!/bin/bash
exec env -i ${pkg_svc_config_path}/fpm-exec \$@
EOM

  fix_interpreter "${pkg_prefix}/bin/*" core/bash bin/bash
  chmod +x "${pkg_prefix}/bin"/*
}

do_build_config() {
  do_default_build_config

  build_line "Merging config from ${php_pkg_ident}"
  cp -nrv "$(pkg_path_for ${php_pkg_ident})"/{config_install,config,hooks} "${pkg_prefix}/"
  toml-merge \
    "$(pkg_path_for ${php_pkg_ident})/default.toml" \
    "${PLAN_CONTEXT}/default.toml" \
    > "${pkg_prefix}/default.toml"
}

do_strip() {
  return 0
}
