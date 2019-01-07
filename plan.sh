pkg_name=php-runtime
pkg_origin=emergence
pkg_version="0.2.0"
pkg_maintainer="Chris Alfano <chris@jarv.us>"
pkg_license=("MIT")
pkg_deps=(
  emergence/php5
  emergence/php-core
  core/libfcgi
  core/git
)

pkg_bin_dirs=(bin)

pkg_binds=(
  [database]="port username password"
)

pkg_exports=(
  [port]=network.port
)


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

  chmod +x "${pkg_prefix}/bin/"*
}

do_strip() {
  return 0
}