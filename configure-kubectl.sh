#!/bin/bash

# write KUBECONFIG
test -e ~/.kube || mkdir ~/.kube
printf '%s' "$KUBE_CONFIG_DATA" | base64 -d >~/.kube/config

# switch to configured namespace
kubectl config set-context --current --namespace="${KUBE_NAMESPACE}"

echo "Outputting: kube-namespace=${KUBE_NAMESPACE}"
echo "kube-namespace=${KUBE_NAMESPACE}" >>"${GITHUB_OUTPUT}"
