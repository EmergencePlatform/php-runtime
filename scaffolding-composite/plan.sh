pkg_name=scaffolding-composite
pkg_origin=emergence
pkg_maintainer="Chris Alfano <chris@jarv.us>"
pkg_license=("MIT")
pkg_build_deps=(
  "${pkg_origin}/php-runtime"
)
pkg_deps=(
  jarvus/toml-merge
)
pkg_scaffolding=core/scaffolding-base


# inherit version from php-runtime
pkg_version() {
  echo "$(pkg_path_for ${pkg_origin}/php-runtime)" | cut -d / -f 6
}

do_before() {
  do_default_before
  update_pkg_version
}
