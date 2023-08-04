#!/bin/bash

echo "Using: KUBE_NAMESPACE=${KUBE_NAMESPACE}"
echo "Using: ENVIRONMENT_NAME=${ENVIRONMENT_NAME}"
echo "Using: ENVIRONMENT_HOSTNAME=${ENVIRONMENT_HOSTNAME}"
echo "Using: HELM_CHART_TREE=${HELM_CHART_TREE}"
echo "Using: DOCKER_NAME=${DOCKER_NAME}"
echo "Using: DOCKER_TAG=${DOCKER_TAG}"


echo
echo "Listing pods existing before deploy"
kubectl get pods \
  -l app.kubernetes.io/instance="${ENVIRONMENT_NAME}" \
  --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' \
| sort \
| tee /tmp/pods-before


echo
echo "Extracting projected helm-chart to temporary directory"
temp_dir=$(mktemp -d)
git archive --format=tar "${HELM_CHART_TREE}" | ( cd "${temp_dir}" && tar -xf - )
echo "Extracted to: ${temp_dir}"


helm_args=(
  --install
  --namespace "${KUBE_NAMESPACE}"
  --set site.name="${ENVIRONMENT_NAME}"
  --set site.title="${KUBE_NAMESPACE}/${ENVIRONMENT_NAME}"
  --set site.image.repository="${DOCKER_NAME}"
  --set site.image.tag="${DOCKER_TAG}"
  --set ingress.enabled=true
  --set site.canonicalHostname="${ENVIRONMENT_HOSTNAME}"
  --set site.displayErrors=true
  --set hab.license=accept-no-persist
)

echo
echo "Using helm upgrade to apply helm-chart to release ${ENVIRONMENT_NAME} with params:" "${helm_args[@]}"
helm upgrade "${ENVIRONMENT_NAME}" "${temp_dir}" "${helm_args[@]}"


echo
echo "Listing pods existing after deploy"
kubectl get pods \
  -l app.kubernetes.io/instance="${ENVIRONMENT_NAME}" \
  --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' \
| sort \
| tee /tmp/pods-after


echo
echo "Deleting stale pods to force image refresh"
comm -12 /tmp/pods-before /tmp/pods-after \
| xargs --no-run-if-empty kubectl delete pod
