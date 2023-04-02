#!/bin/bash

echo "Dropping any existing database..."
kubectl exec "${POD_NAME}" \
  -- hab pkg exec "${SERVICE_NAME}" \
    -- mysqladmin drop "${DATABASE_NAME}" --force \
    || true


echo
echo "Creating an empty database..."
kubectl exec "${POD_NAME}" \
  -- hab pkg exec "${SERVICE_NAME}" \
    -- mysqladmin create "${DATABASE_NAME}"


echo
echo "Loading fixtures..."
(
  for fixture_file in $(git ls-tree -r --name-only "${FIXTURES_TREE}"); do
    git cat-file -p "${FIXTURES_TREE}:${fixture_file}"
  done
) | kubectl exec -i "${POD_NAME}" \
      -- hab pkg exec "${SERVICE_NAME}" \
        -- mysql "${DATABASE_NAME}"


echo
echo "Running migrations..."
kubectl exec "${POD_NAME}" \
  -- hab pkg exec "${SERVICE_NAME}" \
    -- emergence-console-run migrations:execute --all
