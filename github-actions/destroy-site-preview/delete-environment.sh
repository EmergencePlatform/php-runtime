#!/bin/bash

helm uninstall "${ENVIRONMENT_NAME}"
kubectl delete secret "${ENVIRONMENT_NAME}-tls"