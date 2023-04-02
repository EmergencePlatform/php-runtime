#!/bin/bash

if [ -z "${ENVIRONMENT_NAME}" ]; then
  echo "Attempting to determine environment name automatically"

  if [ "${GITHUB_EVENT_NAME}" == "pull_request" ]; then
    ENVIRONMENT_NAME="pr-$(jq --raw-output .pull_request.number "${GITHUB_EVENT_PATH}")"
  elif [ "${GITHUB_REF_NAME}" == "$(jq --raw-output .repository.default_branch "${GITHUB_EVENT_PATH}")" ]; then
    ENVIRONMENT_NAME='latest'
  else
    echo "Could not detect environment name. Either specify environment-name input or only trigger from pull request event"
    exit 1
  fi
fi

echo "Outputting: environment-name=${ENVIRONMENT_NAME}"
echo "environment-name=${ENVIRONMENT_NAME}" >>"${GITHUB_OUTPUT}"
