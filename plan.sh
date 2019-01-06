pkg_name=php-runtime
pkg_origin=emergence
pkg_version="0.1.0"
pkg_maintainer="Chris Alfano <chris@jarv.us>"
pkg_license=("MIT")
pkg_deps=(
  emergence/php5
  emergence/php-core
  core/libfcgi
  core/git
)


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
  return 0
}

do_strip() {
  return 0
}