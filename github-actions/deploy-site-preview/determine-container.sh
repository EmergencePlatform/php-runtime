#!/bin/bash

IMAGE_NAME_FULL="ghcr.io/${GITHUB_REPOSITORY,,}"
if [ -n "${IMAGE_NAME}" ]; then
  IMAGE_NAME_FULL="${IMAGE_NAME_FULL}/${IMAGE_NAME}"
fi

echo "Outputting: image-name-full=${IMAGE_NAME_FULL}"
echo "image-name-full=${IMAGE_NAME_FULL}" >>"${GITHUB_OUTPUT}"

if [ -z "${IMAGE_TAG}" ]; then
  IMAGE_TAG="${ENVIRONMENT_NAME}"
fi

echo "Outputting: image-tag=${IMAGE_TAG}"
echo "image-tag=${IMAGE_TAG}" >>"${GITHUB_OUTPUT}"

IMAGE_TAG_FULL="${IMAGE_NAME_FULL}:${IMAGE_TAG}"

echo "Outputting: image-tag-full=${IMAGE_TAG_FULL}"
echo "image-tag-full=${IMAGE_TAG_FULL}" >>"${GITHUB_OUTPUT}"
