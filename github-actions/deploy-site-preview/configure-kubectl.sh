#!/bin/bash

test -e ~/.kube || mkdir ~/.kube
printf '%s' "$KUBE_CONFIG_DATA" | base64 -d >~/.kube/config
