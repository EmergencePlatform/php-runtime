#!/bin/bash

echo "Uninstalling Helm release..."
helm uninstall "${ENVIRONMENT_NAME}" || true


echo "Deleting TLS secret..."
kubectl delete secret "${ENVIRONMENT_NAME}-tls" || true
