#!/bin/bash

echo "Using: SITE_TREE=${SITE_TREE}"
echo "Using: SITE_VERSION=${SITE_VERSION}"
echo "Using: DOCKER_CACHE_FROM=${DOCKER_CACHE_FROM}"
echo "Using: DOCKER_NAME=${DOCKER_NAME}"
echo "Using: DOCKER_TAG=${DOCKER_TAG}"

echo "Generating build context..."
DOCKER_CONTEXT=$(
    export GIT_INDEX_FILE="${GITHUB_ACTION_PATH}/.gitindex"

    >&2 echo "Reading Dockerfile into object database"
    DOCKERFILE_HASH=$(git hash-object -w "${GITHUB_ACTION_PATH}/Dockerfile")
    >&2 echo "Using DOCKERFILE_HASH=$DOCKERFILE_HASH"

    >&2 echo "Reading tree ${SITE_TREE} into temporary index"
    git read-tree "${SITE_TREE}"

    >&2 echo "Adding Dockerfile(${DOCKERFILE_HASH}) to temporary index"
    git update-index --add --cacheinfo 100644 "${DOCKERFILE_HASH}" Dockerfile

    >&2 echo "Writing temporary index to tree"
    git write-tree
)

echo "Building with Git tree context ${DOCKER_CONTEXT}..."
git archive --format=tar "${DOCKER_CONTEXT}" \
| docker buildx build \
    --cache-to type=inline \
    --cache-from="${DOCKER_CACHE_FROM}" \
    --build-arg="SITE_VERSION=${SITE_VERSION}" \
    --tag="${DOCKER_NAME}:${DOCKER_TAG}" \
    -

echo "Outputting docker-build=${DOCKER_NAME}:${DOCKER_TAG}"
echo "docker-build=${DOCKER_NAME}:${DOCKER_TAG}" >> "${GITHUB_OUTPUT}"
