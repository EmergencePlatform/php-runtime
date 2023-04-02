#!/bin/bash

if [ -z "${ENVIRONMENT_NAME}" ]; then
  echo "Attempting to determine environment name automatically"

  if [ "${GITHUB_EVENT_NAME}" == "pull_request" ]; then
    ENVIRONMENT_NAME="pr-$(jq --raw-output .pull_request.number "${GITHUB_EVENT_PATH}")"
    ENVIRONMENT_TRANSIENT_DEFAULT='true'
  elif [ "${GITHUB_REF_NAME}" == "$(jq --raw-output .repository.default_branch "${GITHUB_EVENT_PATH}")" ]; then
    ENVIRONMENT_NAME='latest'
    ENVIRONMENT_TRANSIENT_DEFAULT='false'
  else
    echo "Could not detect environment name. Either specify environment-name input or only trigger from pull request event"
    exit 1
  fi
fi

if [ -z "${ENVIRONMENT_TRANSIENT}" ]; then
  if [ -n "${ENVIRONMENT_TRANSIENT_DEFAULT}" ]; then
    ENVIRONMENT_TRANSIENT="${ENVIRONMENT_TRANSIENT_DEFAULT}"
  else
    ENVIRONMENT_TRANSIENT='true'
  fi
fi

ENVIRONMENT_HOSTNAME="${ENVIRONMENT_NAME}.${KUBE_HOSTNAME}"

echo "Outputting: environment-name=${ENVIRONMENT_NAME}"
echo "environment-name=${ENVIRONMENT_NAME}" >>"${GITHUB_OUTPUT}"

echo "Outputting: environment-transient=${ENVIRONMENT_TRANSIENT}"
echo "environment-transient=${ENVIRONMENT_TRANSIENT}" >>"${GITHUB_OUTPUT}"

echo "Outputting: environment-hostname=${ENVIRONMENT_HOSTNAME}"
echo "environment-hostname=${ENVIRONMENT_HOSTNAME}" >>"${GITHUB_OUTPUT}"
