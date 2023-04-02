#!/bin/bash


echo "Waiting for rollout to complete..."
SECONDS=0
until kubectl rollout status deployment "${ENVIRONMENT_NAME}"; do
  if ((SECONDS > 300)); then
    echo "Giving up after 5 minutes..."
    exit 1
  fi

  sleep .5
done
echo "Deployment rolled out."


echo
echo "Getting pod name..."
POD_NAME=$(
  kubectl get pod \
    -l app.kubernetes.io/instance="${ENVIRONMENT_NAME}" \
    -o jsonpath='{.items[0].metadata.name}'
)
echo "Outputting: pod-name=${POD_NAME}"
echo "pod-name=${POD_NAME}" >> "${GITHUB_OUTPUT}"


echo
echo "Waiting for pod to be ready..."
kubectl wait --for condition=ready "pod/${POD_NAME}" --timeout=300s
echo "Pod ready."


echo
echo "Finding composite service..."
SERVICE_NAME=$(
  kubectl exec "${POD_NAME}" \
    -- hab svc status \
    | grep '\-composite' \
    | awk '{print $1}'
)
echo "Outputting: service-name=${SERVICE_NAME}"
echo "service-name=${SERVICE_NAME}" >> "${GITHUB_OUTPUT}"


echo
echo "Waiting for MySQL to be ready..."
SECONDS=0
until kubectl exec "${POD_NAME}" -- hab pkg exec "${SERVICE_NAME}" mysqladmin ping; do
  if ((SECONDS > 300)); then
    echo "Giving up after 5 minutes..."
    exit 1
  fi

  sleep .5
done
echo "MySQL ready."


echo
echo "Finding default database..."
# shellcheck disable=SC2016
DATABASE_NAME=$(
  kubectl exec "${POD_NAME}" \
    -- hab pkg exec "${SERVICE_NAME}" \
      -- bash -c 'set -a; source /hab/svc/site/config/env; echo "${MYSQL_DATABASE}"'
)
echo "Outputting: database-name=${DATABASE_NAME}"
echo "database-name=${DATABASE_NAME}" >> "${GITHUB_OUTPUT}"
