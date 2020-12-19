# scaffolding lifecycle:
scaffolding_load() {
  # ensure source is local
  if [ -n "${pkg_source}" ]; then
      exit_with "Please do not use pkg_source in your plan when using scaffolding." 10
  fi

  # prepend runtime deps
  pkg_deps=(
    core/bash
    emergence/php-runtime
    "${pkg_deps[@]}"
  )

  # append bin_dirs
  pkg_bin_dirs=(
    "${pkg_bin_dir[@]}"
    bin
  )

  # append binds
  _set_if_unset pkg_binds database "port username password"

  # append exports
  _set_if_unset pkg_exports port "network.port"
  _set_if_unset pkg_exports status_path "path.status"
  _set_if_unset pkg_exports nginx_server_snippet "nginx.server_snippet"

  # configure projection
  if [ -z "${holo_args}" ]; then
    holo_args="--fetch --working"
    build_line "Setting holo_args=${holo_args}"
  fi

  if [ -z "${holo_branch}" ]; then
    holo_branch="emergence-site"
    build_line "Setting holo_branch=${holo_branch}"
  fi

  # swap in do_default_build_config
  _rename_function "do_default_build_config" "_stock_do_default_build_config"
  _rename_function "_new_do_default_build_config" "do_default_build_config"
}

scaffolding_detect_pkg_version() {
  if [ -n "${SITE_VERSION}" ]; then
    echo "${SITE_VERSION}"
  elif [ -n "${pkg_last_tag}" ] && [ ${pkg_last_tag_distance} -eq 0 ]; then
    echo "${pkg_last_version}"
  else
    echo "${pkg_last_version}-git"
  fi
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

_set_if_unset() {
  local hash key val
  hash="$1"
  key="$2"
  val="$3"

  if [[ ! -v "${hash}[${key}]" ]]; then
    eval "${hash}[${key}]='${val}'"
  fi
}


# override default build lifecycle steps for consumer plans:
do_default_before() {

  # configure git repository path
  pushd "${SRC_PATH}" > /dev/null
  GIT_DIR="$(git rev-parse --git-dir)"
  if [ -z "${GIT_DIR}" ]; then
    exit_with "Build must be run within a git repository" 11
  fi
  export GIT_DIR="$(realpath "${GIT_DIR}")"
  build_line "Setting GIT_DIR=${GIT_DIR}"
  popd > /dev/null

  # load version information from git
  if [ -z "${SITE_VERSION}" ]; then
    pkg_commit="$(git rev-parse --short HEAD)"
    pkg_last_tag="$(git describe --tags --abbrev=0 ${pkg_commit} 2>/dev/null || true)"

    if [ -n "${pkg_last_tag}" ]; then
      pkg_last_version=${pkg_last_tag#v}
      pkg_last_tag_distance="$(git rev-list ${pkg_last_tag}..${pkg_commit} --count)"
    else
      pkg_last_version="0.0.0"
    fi
  fi

  # initialize pkg_version
  update_pkg_version

  # localize environmental paths
  set_runtime_env -f PHP_EXTENSION_DIR "${pkg_svc_config_install_path}/extensions-${PHP_ZEND_API_VERSION}"
  set_runtime_env -f PHPRC "${pkg_svc_config_install_path}"
  set_runtime_env -f MYSQL_HOME "${pkg_svc_config_path}"
}

do_default_build() {
  if [ -n "${SITE_TREE}" ]; then
    holo_output_hash="${SITE_TREE}"
  else
    # disable ssh key verification for any fetch operations, our environment is disposable anyway
    export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

    pushd "${SRC_PATH}" > /dev/null
    holo_cmd="git holo project ${holo_args} ${holo_branch}"
    build_line "Running: ${holo_cmd}"
    holo_output_hash="$($holo_cmd)"
    popd > /dev/null
  fi
}

do_default_install() {
  build_line "Installing site"
  mkdir "${pkg_prefix}/site"
  git archive --format=tar "${holo_output_hash}" | (cd "${pkg_prefix}/site" && tar xf -)

  build_line "Installing web root"
  mkdir -p "${pkg_prefix}/web/public"
  cp -rv "$(pkg_path_for emergence/php-runtime)/web"/* "${pkg_prefix}/web/"

  build_line "Generating initialize.php wrapper"
  cat > "${pkg_prefix}/web/initialize.php" <<- EOM
<?php

require('${pkg_svc_config_path}/initialize.php');
EOM

  build_line "Generating emergence-php-exec wrapper"
  cat > "${pkg_prefix}/bin/emergence-php-exec" <<- EOM
#!/bin/bash
exec ${pkg_svc_config_path}/fpm-exec \$@
EOM

  fix_interpreter "${pkg_prefix}/bin/*" core/bash bin/bash
  chmod +x "${pkg_prefix}/bin"/*
}

# this function gets renamed to `do_default_build_config`
_new_do_default_build_config() {
  _stock_do_default_build_config

  build_line "Merging php-runtime config"
  cp -nrv "$(pkg_path_for emergence/php-runtime)"/{config_install,config,hooks} "${pkg_prefix}/"
  toml-merge \
    "$(pkg_path_for emergence/php-runtime)/default.toml" \
    - \
    "${PLAN_CONTEXT}/default.toml" \
    > "${pkg_prefix}/default.toml" <<- END_OF_TOML
      [core]
        debug = false
        production = true

      [extensions.opcache.config]
        validate_timestamps = false
END_OF_TOML
}

do_default_strip() {
  return 0
}
